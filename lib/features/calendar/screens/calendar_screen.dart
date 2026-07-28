import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/pomodoro/pomodoro_timer_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';
import 'package:mobile/core/widgets/editorial_states.dart';
import 'package:mobile/core/widgets/editorial_surface_card.dart';
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
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: Text(context.t('calendar.addTask')),
      ),
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: _loadMonth,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
          children: [
            EditorialPageHeader(
              title: context.t('calendar.title'),
              subtitle: context.t('calendar.subtitle'),
              action: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final today = _day(DateTime.now());
                    setState(() {
                      _selected = today;
                      _displayedMonth = DateTime(today.year, today.month);
                    });
                    _loadMonth();
                  },
                  icon: Icon(Icons.today_outlined, size: 18, color: p.accent),
                  label: Text(
                    context.t('calendar.today'),
                    style: AppTypography.accentLabel(context),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pomodoro.isActive) ...[
                    _ActivePomodoroCard(timer: _pomodoro),
                    const SizedBox(height: 14),
                  ],
                  EditorialSurfaceCard(
                    elevated: false,
                    padding: EdgeInsets.zero,
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
                    style: AppTypography.sectionTitle(context),
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: CircularProgressIndicator(color: p.accent),
                      ),
                    )
                  else if (_error != null)
                    EditorialErrorState(message: _error!, onRetry: _loadMonth)
                  else if (_selectedEntries.isEmpty)
                    EditorialEmptyState(message: context.t('calendar.emptyDay'))
                  else
                    ..._selectedEntries.map(
                      (entry) => _EntryCard(
                        entry: entry,
                        isActiveFocus: _pomodoro.activeEntryId == entry.id,
                        isPaused:
                            _pomodoro.isPaused &&
                            _pomodoro.activeEntryId == entry.id,
                        onChanged: (value) => _toggle(entry, value),
                        onEdit: () => _edit(entry),
                        onDelete: () => _delete(entry),
                        onStartFocus: () => _startTimer(entry),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
    final p = context.palette;
    final accent = timer.isRunning ? p.accent : p.warning;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
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
                  style: AppTypography.button(context, size: 12, color: accent)
                      .copyWith(
                        fontWeight: FontWeight.w700,
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
                  timer.isPaused
                      ? context.t('calendar.paused')
                      : context.t('calendar.timerActive'),
                  style: AppTypography.meta(context, color: accent),
                ),
                const SizedBox(height: 4),
                Text(
                  timer.entryMeta?.title ?? context.t('calendar.pomodoro'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle(context, size: 15),
                ),
              ],
            ),
          ),
          if (timer.isRunning)
            IconButton(
              tooltip: context.t('calendar.pauseTimer'),
              onPressed: timer.pauseTimer,
              icon: const Icon(Icons.pause_rounded),
              color: accent,
            )
          else
            IconButton(
              tooltip: context.t('calendar.resumeTimer'),
              onPressed: timer.resumeTimer,
              icon: const Icon(Icons.play_arrow_rounded),
              color: accent,
            ),
          IconButton(
            tooltip: context.t('calendar.stopTimer'),
            onPressed: timer.stopTimer,
            icon: const Icon(Icons.stop_rounded),
            color: p.muted,
          ),
        ],
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
  Widget build(BuildContext context) {
    final p = context.palette;
    return EditorialSurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      elevated: false,
      showAccentBar: isActiveFocus,
      accentColor: p.accent,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox.adaptive(
            value: entry.completed,
            activeColor: p.accent,
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
                    style: AppTypography.cardTitle(context, size: 16).copyWith(
                      decoration: entry.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: isActiveFocus ? p.accent : p.foreground,
                    ),
                  ),
                  if (entry.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 5),
                    Text(
                      entry.note!,
                      style: AppTypography.body(context, size: 12),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    isActiveFocus
                        ? (isPaused
                              ? 'Pomodoro đang tạm dừng'
                              : 'Đang chạy Pomodoro')
                        : '${entry.pomodoroMinutes} phút · ${entry.pomodoroCompleted} phiên · ${_focusTime(entry.totalFocusSeconds)} tập trung',
                    style:
                        AppTypography.meta(
                          context,
                          color: isActiveFocus ? p.accent : p.muted,
                        ).copyWith(
                          fontWeight: isActiveFocus
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: isActiveFocus
                ? (isPaused
                      ? context.t('calendar.resumeTimer')
                      : context.t('calendar.timerActive'))
                : context.t('calendar.startTimer'),
            onPressed: entry.completed ? null : onStartFocus,
            icon: Icon(
              isActiveFocus
                  ? (isPaused ? Icons.play_arrow_rounded : Icons.timelapse)
                  : Icons.timer_outlined,
              color: isActiveFocus ? p.accent : p.muted,
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: p.muted),
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(context.t('common.edit')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(context.t('common.delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
