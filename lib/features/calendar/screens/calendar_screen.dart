import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/pomodoro/pomodoro_timer_controller.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/data/models/productivity_dtos.dart';
import 'package:mobile/data/repositories/calendar_repository.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _repository = BeBlogCalendarRepository();
  final _pomodoro = PomodoroTimerController.instance;
  DateTime? _observedCompletedAt;
  DateTime _selected = _day(DateTime.now());
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  List<CalendarEntryDto> _entries = const [];
  bool _loading = true;
  String? _error;

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    _observedCompletedAt = _pomodoro.lastCompletedAt;
    _pomodoro.addListener(_onPomodoroChanged);
    _loadMonth();
  }

  @override
  void dispose() {
    _pomodoro.removeListener(_onPomodoroChanged);
    super.dispose();
  }

  void _onPomodoroChanged() {
    if (!mounted) return;
    setState(() {});
    final completed = _pomodoro.lastCompletedAt;
    if (completed != null && completed != _observedCompletedAt) {
      _observedCompletedAt = completed;
      unawaited(_loadMonth());
    }
    final error = _pomodoro.lastError;
    if (error != null) {
      _pomodoro.lastError = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _loadMonth() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final from = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final to = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final result = await _repository.getEntries(from: from, to: to);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _entries = result.data ?? const [];
      _error = result.success
          ? null
          : (result.message ?? 'Không tải được lịch cá nhân.');
    });
  }

  List<CalendarEntryDto> get _selectedEntries => _entries
      .where((entry) => DateUtils.isSameDay(entry.eventDate, _selected))
      .toList();

  Future<void> _edit([CalendarEntryDto? entry]) async {
    final updated = await showDialog<CalendarEntryDto>(
      context: context,
      builder: (context) => _EntryDialog(
        entry: entry,
        selectedDate: entry?.eventDate ?? _selected,
      ),
    );
    if (updated == null) return;
    final result = entry == null
        ? await _repository.create(updated)
        : await _repository.update(updated);
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Không lưu được công việc.')),
      );
      return;
    }
    _selected = _day(updated.eventDate);
    _displayedMonth = DateTime(_selected.year, _selected.month);
    unawaited(_loadMonth());
  }

  Future<void> _toggle(CalendarEntryDto entry, bool completed) async {
    final result = await _repository.update(
      entry.copyWith(completed: completed),
    );
    if (result.success) unawaited(_loadMonth());
  }

  Future<void> _delete(CalendarEntryDto entry) async {
    final confirmed = await showEditorialConfirmDialog(
      context,
      title: 'Xóa công việc?',
      message: '“${entry.title}” sẽ bị xóa khỏi lịch.',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed) return;
    final result = await _repository.delete(entry.id);
    if (result.success) unawaited(_loadMonth());
  }

  void _startTimer(CalendarEntryDto entry) {
    if (_pomodoro.isActive && _pomodoro.activeEntryId != entry.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang có phiên Pomodoro khác — hãy kết thúc trước.'),
        ),
      );
      return;
    }
    if (_pomodoro.activeEntryId == entry.id) {
      if (_pomodoro.isPaused) {
        _pomodoro.resumeTimer();
      }
      return;
    }
    _pomodoro.startTimer(entry);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(
      title: const Text('Lịch & tập trung'),
      actions: [
        IconButton(
          tooltip: 'Hôm nay',
          onPressed: () {
            final today = _day(DateTime.now());
            setState(() {
              _selected = today;
              _displayedMonth = DateTime(today.year, today.month);
            });
            _loadMonth();
          },
          icon: const Icon(Icons.today_outlined),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      backgroundColor: AppColors.primaryBrown,
      foregroundColor: Colors.white,
      shape: const StadiumBorder(),
      icon: const Icon(Icons.add),
      label: const Text('Công việc'),
    ),
    body: RefreshIndicator(
      onRefresh: _loadMonth,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_pomodoro.isActive) ...[
            _ActivePomodoroCard(timer: _pomodoro),
            const SizedBox(height: 14),
          ],
          Card(
            elevation: 0,
            child: CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                final monthChanged =
                    date.month != _displayedMonth.month ||
                    date.year != _displayedMonth.year;
                setState(() {
                  _selected = _day(date);
                  _displayedMonth = DateTime(date.year, date.month);
                });
                if (monthChanged) _loadMonth();
              },
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${_weekday(_selected.weekday)}, ${_selected.day}/${_selected.month}/${_selected.year}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            )
          else if (_error != null)
            Card(
              color: AppColors.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          else if (_selectedEntries.isEmpty)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ngày này chưa có công việc.'),
              ),
            )
          else
            ..._selectedEntries.map(
              (entry) => _EntryCard(
                entry: entry,
                isActiveFocus: _pomodoro.activeEntryId == entry.id,
                isPaused:
                    _pomodoro.isPaused && _pomodoro.activeEntryId == entry.id,
                onChanged: (value) => _toggle(entry, value),
                onEdit: () => _edit(entry),
                onDelete: () => _delete(entry),
                onStartFocus: () => _startTimer(entry),
              ),
            ),
        ],
      ),
    ),
  );

  String _weekday(int weekday) => const [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ][weekday - 1];
}

class _ActivePomodoroCard extends StatelessWidget {
  final PomodoroTimerController timer;

  const _ActivePomodoroCard({required this.timer});

  static String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final accent = timer.isRunning
        ? AppColors.primaryBrown
        : const Color(0xFFD97706);
    return Card(
      elevation: 0,
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: accent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: timer.progress,
                    strokeWidth: 3.5,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    color: accent,
                  ),
                  Text(
                    _format(timer.remainingSeconds),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timer.isPaused ? 'Đã tạm dừng' : 'Đang tập trung',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timer.entryMeta?.title ?? 'Pomodoro',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (timer.isRunning)
              IconButton(
                tooltip: 'Tạm dừng',
                onPressed: timer.pauseTimer,
                icon: const Icon(Icons.pause_rounded),
                color: accent,
              )
            else
              IconButton(
                tooltip: 'Tiếp tục',
                onPressed: timer.resumeTimer,
                icon: const Icon(Icons.play_arrow_rounded),
                color: accent,
              ),
            IconButton(
              tooltip: 'Kết thúc',
              onPressed: timer.stopTimer,
              icon: const Icon(Icons.stop_rounded),
              color: AppColors.homeTextLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final CalendarEntryDto entry;
  final bool isActiveFocus;
  final bool isPaused;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStartFocus;

  const _EntryCard({
    required this.entry,
    this.isActiveFocus = false,
    this.isPaused = false,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: isActiveFocus
        ? AppColors.primaryBrown.withValues(alpha: 0.06)
        : null,
    shape: isActiveFocus
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: AppColors.primaryBrown.withValues(alpha: 0.3),
            ),
          )
        : null,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox.adaptive(
            value: entry.completed,
            onChanged: (value) => onChanged(value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: entry.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (entry.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      entry.note!,
                      style: const TextStyle(
                        color: AppColors.homeTextLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    isActiveFocus
                        ? (isPaused
                              ? 'Pomodoro đang tạm dừng'
                              : 'Đang chạy Pomodoro')
                        : '${entry.pomodoroMinutes} phút · ${entry.pomodoroCompleted} phiên · ${_focusTime(entry.totalFocusSeconds)} tập trung',
                    style: TextStyle(
                      fontSize: 10,
                      color: isActiveFocus
                          ? AppColors.primaryBrown
                          : AppColors.homeTextLight,
                      fontWeight: isActiveFocus
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: isActiveFocus
                ? (isPaused ? 'Tiếp tục' : 'Đang tập trung')
                : 'Bắt đầu tập trung',
            onPressed: entry.completed ? null : onStartFocus,
            icon: Icon(
              isActiveFocus
                  ? (isPaused ? Icons.play_arrow_rounded : Icons.timelapse)
                  : Icons.timer_outlined,
              color: isActiveFocus ? AppColors.primaryBrown : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Chỉnh sửa')),
              PopupMenuItem(value: 'delete', child: Text('Xóa')),
            ],
          ),
        ],
      ),
    ),
  );

  static String _focusTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _EntryDialog extends StatefulWidget {
  final CalendarEntryDto? entry;
  final DateTime selectedDate;

  const _EntryDialog({required this.entry, required this.selectedDate});

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late DateTime _date;
  late double _minutes;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.entry?.title);
    _note = TextEditingController(text: widget.entry?.note);
    _date = widget.entry?.eventDate ?? widget.selectedDate;
    _minutes = (widget.entry?.pomodoroMinutes ?? 25).toDouble();
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    final current = widget.entry;
    Navigator.pop(
      context,
      CalendarEntryDto(
        id: current?.id ?? '',
        userId: current?.userId ?? '',
        eventDate: _date,
        title: _title.text.trim(),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        completed: current?.completed ?? false,
        completedAt: current?.completedAt,
        pomodoroMinutes: _minutes.round(),
        pomodoroCompleted: current?.pomodoroCompleted ?? 0,
        totalFocusSeconds: current?.totalFocusSeconds ?? 0,
        createdAt: current?.createdAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.entry == null ? 'Công việc mới' : 'Sửa công việc'),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Tiêu đề *'),
            ),
            TextField(
              controller: _note,
              maxLength: 2000,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ghi chú'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text('${_date.day}/${_date.month}/${_date.year}'),
              onTap: () async {
                final value = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (value != null) setState(() => _date = value);
              },
            ),
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _minutes,
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${_minutes.round()} phút',
                    onChanged: (value) => setState(() => _minutes = value),
                  ),
                ),
                Text('${_minutes.round()}m'),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: _save, child: const Text('Lưu')),
    ],
  );
}
