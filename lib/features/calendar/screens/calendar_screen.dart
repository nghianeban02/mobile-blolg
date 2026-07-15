import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
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
    _loadMonth();
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
    _loadMonth();
  }

  Future<void> _toggle(CalendarEntryDto entry, bool completed) async {
    final result = await _repository.update(
      entry.copyWith(completed: completed),
    );
    if (result.success) _loadMonth();
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
    if (result.success) _loadMonth();
  }

  Future<void> _startTimer(CalendarEntryDto entry) async {
    final recorded = await showModalBottomSheet<_FocusResult>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _PomodoroSheet(entry: entry),
    );
    if (recorded == null || recorded.focusSeconds <= 0) return;
    final updated = entry.copyWith(
      pomodoroCompleted: entry.pomodoroCompleted + (recorded.completed ? 1 : 0),
      totalFocusSeconds: entry.totalFocusSeconds + recorded.focusSeconds,
    );
    await _repository.update(updated);
    _loadMonth();
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
      icon: const Icon(Icons.add),
      label: const Text('Công việc'),
    ),
    body: RefreshIndicator(
      onRefresh: _loadMonth,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
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

class _EntryCard extends StatelessWidget {
  final CalendarEntryDto entry;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStartFocus;

  const _EntryCard({
    required this.entry,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: Colors.white,
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
                    '${entry.pomodoroMinutes} phút · ${entry.pomodoroCompleted} phiên · ${_focusTime(entry.totalFocusSeconds)} tập trung',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.homeTextLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Bắt đầu tập trung',
            onPressed: entry.completed ? null : onStartFocus,
            icon: const Icon(Icons.timer_outlined),
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

class _FocusResult {
  final int focusSeconds;
  final bool completed;

  const _FocusResult({required this.focusSeconds, required this.completed});
}

class _PomodoroSheet extends StatefulWidget {
  final CalendarEntryDto entry;

  const _PomodoroSheet({required this.entry});

  @override
  State<_PomodoroSheet> createState() => _PomodoroSheetState();
}

class _PomodoroSheetState extends State<_PomodoroSheet>
    with WidgetsBindingObserver {
  Timer? _ticker;
  late final int _totalSeconds;
  late int _remaining;
  DateTime? _deadline;
  bool _running = false;

  int get _elapsed => _totalSeconds - _remaining;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _totalSeconds = widget.entry.pomodoroMinutes * 60;
    _remaining = _totalSeconds;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncClock();
  }

  void _toggle() {
    if (_running) {
      _syncClock();
      _ticker?.cancel();
      setState(() {
        _running = false;
        _deadline = null;
      });
      return;
    }
    _deadline = DateTime.now().add(Duration(seconds: _remaining));
    setState(() => _running = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _syncClock());
  }

  void _syncClock() {
    final deadline = _deadline;
    if (!_running || deadline == null || !mounted) return;
    final remaining = deadline
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, _totalSeconds);
    setState(() => _remaining = remaining);
    if (remaining == 0) {
      _ticker?.cancel();
      Navigator.pop(
        context,
        _FocusResult(focusSeconds: _totalSeconds, completed: true),
      );
    }
  }

  Future<void> _close() async {
    final shouldSave = _elapsed > 0
        ? await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Kết thúc phiên?'),
              content: const Text('Thời gian đã tập trung sẽ được ghi lại.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Tiếp tục'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Kết thúc'),
                ),
              ],
            ),
          )
        : true;
    if (shouldSave == true && mounted) {
      Navigator.pop(
        context,
        _FocusResult(focusSeconds: _elapsed, completed: false),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.self_improvement,
                    color: AppColors.primaryBrown,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(onPressed: _close, icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                '$minutes:$seconds',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 66,
                  fontWeight: FontWeight.w600,
                  color: AppColors.homeTextDark,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 84,
                height: 84,
                child: FloatingActionButton(
                  heroTag: 'pomodoro-control',
                  onPressed: _toggle,
                  backgroundColor: AppColors.primaryBrown,
                  foregroundColor: Colors.white,
                  child: Icon(
                    _running ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_running ? 'Đang tập trung' : 'Sẵn sàng bắt đầu'),
            ],
          ),
        ),
      ),
    );
  }
}
