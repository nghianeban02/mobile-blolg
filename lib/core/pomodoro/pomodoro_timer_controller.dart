import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mobile/data/models/productivity_dtos.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';

enum PomodoroTimerStatus { idle, running, paused }

/// Metadata entry gắn với phiên Pomodoro đang chạy (mirror web).
class PomodoroEntryMeta {
  final String id;
  final String userId;
  final String title;
  final DateTime eventDate;
  final String? note;
  final bool completed;
  final int pomodoroMinutes;
  final int pomodoroCompleted;
  final int totalFocusSeconds;

  const PomodoroEntryMeta({
    required this.id,
    required this.userId,
    required this.title,
    required this.eventDate,
    this.note,
    this.completed = false,
    this.pomodoroMinutes = 25,
    this.pomodoroCompleted = 0,
    this.totalFocusSeconds = 0,
  });

  factory PomodoroEntryMeta.fromEntry(CalendarEntryDto entry) =>
      PomodoroEntryMeta(
        id: entry.id,
        userId: entry.userId,
        title: entry.title,
        eventDate: entry.eventDate,
        note: entry.note,
        completed: entry.completed,
        pomodoroMinutes: entry.pomodoroMinutes,
        pomodoroCompleted: entry.pomodoroCompleted,
        totalFocusSeconds: entry.totalFocusSeconds,
      );

  CalendarEntryDto toEntry({
    int? pomodoroCompleted,
    int? totalFocusSeconds,
  }) =>
      CalendarEntryDto(
        id: id,
        userId: userId,
        eventDate: eventDate,
        title: title,
        note: note,
        completed: completed,
        pomodoroMinutes: pomodoroMinutes,
        pomodoroCompleted: pomodoroCompleted ?? this.pomodoroCompleted,
        totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      );
}

/// Timer Pomodoro toàn app — tương đương `usePomodoroTimer` + context trên web.
class PomodoroTimerController extends ChangeNotifier {
  PomodoroTimerController({BeBlogCalendarRepository? repository})
      : _repository = repository ?? BeBlogCalendarRepository();

  static final PomodoroTimerController instance = PomodoroTimerController();

  final BeBlogCalendarRepository _repository;

  PomodoroTimerStatus status = PomodoroTimerStatus.idle;
  PomodoroEntryMeta? entryMeta;
  int remainingSeconds = 0;
  int totalSeconds = 0;
  DateTime? lastCompletedAt;
  String? lastError;

  Timer? _ticker;
  DateTime? _deadline;
  int _pausedRemainingMs = 0;

  bool get isActive => status != PomodoroTimerStatus.idle;
  bool get isRunning => status == PomodoroTimerStatus.running;
  bool get isPaused => status == PomodoroTimerStatus.paused;
  String? get activeEntryId => entryMeta?.id;

  double get progress {
    if (totalSeconds <= 0) return 0;
    return ((totalSeconds - remainingSeconds) / totalSeconds).clamp(0.0, 1.0);
  }

  void startTimer(CalendarEntryDto entry) {
    _clearTick();
    final secs = entry.pomodoroMinutes * 60;
    entryMeta = PomodoroEntryMeta.fromEntry(entry);
    totalSeconds = secs;
    remainingSeconds = secs;
    _pausedRemainingMs = 0;
    lastError = null;
    _deadline = DateTime.now().add(Duration(seconds: secs));
    status = PomodoroTimerStatus.running;
    _startTick();
    notifyListeners();
  }

  void pauseTimer() {
    if (!isRunning || _deadline == null) return;
    _pausedRemainingMs = _deadline!.difference(DateTime.now()).inMilliseconds;
    if (_pausedRemainingMs < 0) _pausedRemainingMs = 0;
    _deadline = null;
    _clearTick();
    remainingSeconds = (_pausedRemainingMs / 1000).ceil();
    status = PomodoroTimerStatus.paused;
    notifyListeners();
  }

  void resumeTimer() {
    if (!isPaused || _pausedRemainingMs <= 0) return;
    _deadline = DateTime.now().add(Duration(milliseconds: _pausedRemainingMs));
    _pausedRemainingMs = 0;
    status = PomodoroTimerStatus.running;
    _startTick();
    notifyListeners();
  }

  void stopTimer() {
    _resetIdle();
    notifyListeners();
  }

  void _startTick() {
    _clearTick();
    _syncRemaining();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _syncRemaining();
    });
  }

  void _syncRemaining() {
    final deadline = _deadline;
    if (deadline == null || !isRunning) return;
    final remaining =
        deadline.difference(DateTime.now()).inSeconds.clamp(0, totalSeconds);
    if (remaining != remainingSeconds) {
      remainingSeconds = remaining;
      notifyListeners();
    }
    if (remaining <= 0) {
      unawaited(_finishCompleted());
    }
  }

  Future<void> _finishCompleted() async {
    final meta = entryMeta;
    final duration = totalSeconds;
    _resetIdle();
    lastCompletedAt = DateTime.now();
    notifyListeners();
    if (meta == null || duration <= 0) return;
    final result = await _repository.update(
      meta.toEntry(
        pomodoroCompleted: meta.pomodoroCompleted + 1,
        totalFocusSeconds: meta.totalFocusSeconds + duration,
      ),
    );
    if (!result.success) {
      lastError = result.message ?? 'Không lưu được phiên Pomodoro.';
      notifyListeners();
    }
  }

  void _resetIdle() {
    _clearTick();
    _deadline = null;
    _pausedRemainingMs = 0;
    status = PomodoroTimerStatus.idle;
    entryMeta = null;
    remainingSeconds = 0;
    totalSeconds = 0;
  }

  void _clearTick() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _clearTick();
    super.dispose();
  }
}
