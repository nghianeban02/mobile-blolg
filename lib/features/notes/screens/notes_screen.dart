import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_typography.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
import 'package:mobile/core/widgets/editorial_filter_tabs.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';
import 'package:mobile/core/widgets/editorial_states.dart';
import 'package:mobile/data/models/productivity_dtos.dart';
import 'package:mobile/data/repositories/notes_repository.dart';
import 'package:mobile/features/notes/screens/note_editor_screen.dart';

enum _NotesTab { active, archived, trash }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repository = BeBlogNotesRepository();
  final _search = TextEditingController();
  Timer? _debounce;

  _NotesTab _tab = _NotesTab.active;
  bool _loading = true;
  String? _error;
  String? _folderId;
  List<NoteDto> _notes = const [];
  List<NoteFolderDto> _folders = const [];
  List<NoteLabelDto> _labels = const [];
  NoteStatsDto _stats = const NoteStatsDto();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final query = _search.text.trim();
    final notesResult = await (query.isNotEmpty
        ? _repository.search(query)
        : switch (_tab) {
            _NotesTab.active => _repository.getNotes(folderId: _folderId),
            _NotesTab.archived => _repository.getArchived(),
            _NotesTab.trash => _repository.getTrash(),
          });
    final statsResult = await _repository.stats();
    final foldersResult = await _repository.getFolders();
    final labelsResult = await _repository.getLabels();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _notes = notesResult.data ?? const [];
      _stats = statsResult.data ?? _stats;
      _folders = foldersResult.data ?? _folders;
      _labels = labelsResult.data ?? _labels;
      _error = notesResult.success
          ? null
          : (notesResult.message ?? 'Không tải được ghi chú.');
    });
  }

  Future<void> _openEditor([NoteDto? note]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(noteId: note?.id, initialFolderId: _folderId),
      ),
    );
    if (changed == true) unawaited(_load());
  }

  Future<void> _runAction(
    Future<Object> Function() action, {
    String? success,
  }) async {
    await action();
    if (!mounted) return;
    if (success != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(success)));
    }
    unawaited(_load());
  }

  Future<void> _deleteNote(NoteDto note, {bool permanent = false}) async {
    final confirmed = await showEditorialConfirmDialog(
      context,
      title: permanent ? 'Xóa vĩnh viễn?' : 'Chuyển vào thùng rác?',
      message: permanent
          ? 'Ghi chú này không thể khôi phục sau khi xóa.'
          : 'Bạn có thể khôi phục ghi chú từ thùng rác.',
      confirmLabel: permanent ? 'Xóa vĩnh viễn' : 'Chuyển vào thùng rác',
      destructive: true,
    );
    if (!confirmed) return;
    await _runAction(
      () => permanent
          ? _repository.permanentDelete(note.id)
          : _repository.moveToTrash(note.id),
    );
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showEditorialConfirmDialog(
      context,
      title: 'Dọn sạch thùng rác?',
      message: 'Tất cả ghi chú trong thùng rác sẽ bị xóa vĩnh viễn.',
      confirmLabel: 'Dọn sạch',
      destructive: true,
    );
    if (!confirmed) return;
    await _runAction(_repository.emptyTrash);
  }

  Future<void> _manageCollections() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CollectionsSheet(
        repository: _repository,
        folders: _folders,
        labels: _labels,
      ),
    );
    unawaited(_load());
  }

  String _tabId(_NotesTab tab) => switch (tab) {
    _NotesTab.active => 'active',
    _NotesTab.archived => 'archived',
    _NotesTab.trash => 'trash',
  };

  _NotesTab _tabFromId(String id) => switch (id) {
    'archived' => _NotesTab.archived,
    'trash' => _NotesTab.trash,
    _ => _NotesTab.active,
  };

  String _emptyMessage(BuildContext context) => switch (_tab) {
    _NotesTab.active => context.t('notes.empty'),
    _NotesTab.archived => context.t('notes.emptyArchived'),
    _NotesTab.trash => context.t('notes.emptyTrash'),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      floatingActionButton: _tab == _NotesTab.active
          ? FloatingActionButton(
              onPressed: _openEditor,
              backgroundColor: p.accent,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        color: p.accent,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
          children: [
            EditorialPageHeader(
              title: context.t('notes.title'),
              subtitle: context.t('notes.subtitle'),
              action: Row(
                children: [
                  IconButton(
                    tooltip: context.t('notes.folders'),
                    onPressed: _manageCollections,
                    icon: Icon(Icons.folder_copy_outlined, color: p.foreground),
                  ),
                  if (_tab == _NotesTab.trash && _notes.isNotEmpty)
                    IconButton(
                      tooltip: context.t('notes.emptyTrashBtn'),
                      onPressed: _emptyTrash,
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: p.foreground,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _search,
                    style: AppTypography.body(
                      context,
                      color: p.foreground,
                      size: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: context.t('notes.search'),
                      hintStyle: AppTypography.body(
                        context,
                        color: p.muted.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: p.muted),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _search.clear,
                              icon: Icon(Icons.close, color: p.muted),
                            ),
                      filled: true,
                      fillColor: p.fieldFill,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.input,
                        borderSide: BorderSide(
                          color: p.accent.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  EditorialFilterTabs(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    tabs: [
                      EditorialFilterTab(
                        id: 'active',
                        label: context.t('notes.tabAll'),
                        count: _stats.active,
                      ),
                      EditorialFilterTab(
                        id: 'archived',
                        label: context.t('notes.tabArchived'),
                        count: _stats.archived,
                      ),
                      EditorialFilterTab(
                        id: 'trash',
                        label: context.t('notes.tabTrash'),
                        count: _stats.trashed,
                      ),
                    ],
                    activeId: _tabId(_tab),
                    onChanged: (id) {
                      setState(() => _tab = _tabFromId(id));
                      _load();
                    },
                  ),
                  if (_tab == _NotesTab.active && _folders.isNotEmpty) ...[
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ChoiceChip(
                            label: Text(context.t('notes.tabAll')),
                            shape: const StadiumBorder(),
                            selected: _folderId == null,
                            selectedColor: p.accentSoft,
                            labelStyle: AppTypography.accentLabel(
                              context,
                              color: _folderId == null ? p.accent : p.muted,
                            ),
                            onSelected: (_) {
                              setState(() => _folderId = null);
                              _load();
                            },
                          ),
                          const SizedBox(width: 8),
                          ..._folders.map(
                            (folder) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  '${folder.icon ?? '📁'} ${folder.name}',
                                ),
                                shape: const StadiumBorder(),
                                selected: _folderId == folder.id,
                                selectedColor: p.accentSoft,
                                labelStyle: AppTypography.accentLabel(
                                  context,
                                  color: _folderId == folder.id
                                      ? p.accent
                                      : p.muted,
                                ),
                                onSelected: (_) {
                                  setState(() => _folderId = folder.id);
                                  _load();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: CircularProgressIndicator(color: p.accent),
                      ),
                    )
                  else if (_error != null)
                    EditorialErrorState(message: _error!, onRetry: _load)
                  else if (_notes.isEmpty)
                    EditorialEmptyState(message: _emptyMessage(context))
                  else
                    ..._notes.map(
                      (note) => _NoteCard(
                        note: note,
                        tab: _tab,
                        onOpen: () => _openEditor(note),
                        onPin: () =>
                            _runAction(() => _repository.togglePin(note.id)),
                        onArchive: () => _runAction(
                          () => note.archived
                              ? _repository.unarchive(note.id)
                              : _repository.archive(note.id),
                        ),
                        onDuplicate: () => _runAction(
                          () => _repository.duplicate(note.id),
                          success: 'Đã nhân bản ghi chú.',
                        ),
                        onRestore: () =>
                            _runAction(() => _repository.restore(note.id)),
                        onDelete: () => _deleteNote(
                          note,
                          permanent: _tab == _NotesTab.trash,
                        ),
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
}

class _NoteCard extends StatelessWidget {
  final NoteDto note;
  final _NotesTab tab;
  final VoidCallback onOpen;
  final VoidCallback onPin;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.tab,
    required this.onOpen,
    required this.onPin,
    required this.onArchive,
    required this.onDuplicate,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _noteColor(note.color, p),
        borderRadius: AppRadius.card,
        border: Border.all(color: p.border),
        boxShadow: note.pinned && !p.isDark ? AppShadows.soft : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tab == _NotesTab.trash ? null : onOpen,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.icon != null && note.icon!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      note.icon!,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.pinned) ...[
                            Icon(Icons.push_pin, size: 14, color: p.accent),
                            const SizedBox(width: 5),
                          ],
                          Expanded(
                            child: Text(
                              note.title.isEmpty
                                  ? context.t('notes.untitled')
                                  : note.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.cardTitle(context, size: 19),
                            ),
                          ),
                        ],
                      ),
                      if (note.preview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note.preview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body(context, size: 13),
                        ),
                      ],
                      if (note.labels.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: note.labels
                              .map(
                                (label) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: p.surface,
                                  shape: StadiumBorder(
                                    side: BorderSide(color: p.border),
                                  ),
                                  label: Text(
                                    label.name,
                                    style: AppTypography.meta(context),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        '${note.wordCount} ${context.t('notes.words')} · ${formatCommentDateTime(note.lastEditedAt ?? note.updatedAt ?? note.createdAt)}',
                        style: AppTypography.meta(context),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: p.muted),
                  onSelected: (value) {
                    switch (value) {
                      case 'pin':
                        onPin();
                      case 'archive':
                        onArchive();
                      case 'duplicate':
                        onDuplicate();
                      case 'restore':
                        onRestore();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    if (tab == _NotesTab.active) ...[
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(
                          note.pinned
                              ? context.t('notes.unpin')
                              : context.t('notes.pin'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(context.t('notes.archive')),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(context.t('notes.duplicate')),
                      ),
                    ],
                    if (tab == _NotesTab.archived)
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(context.t('notes.unarchive')),
                      ),
                    if (tab == _NotesTab.trash)
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(context.t('notes.restore')),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        tab == _NotesTab.trash
                            ? context.t('notes.permanentDelete')
                            : context.t('notes.delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _noteColor(String name, AppPalette p) => switch (name) {
    'red' => const Color(0xFFFFE8E5),
    'orange' => const Color(0xFFFFEBD9),
    'yellow' => const Color(0xFFFFF5CC),
    'green' => const Color(0xFFE3F4E8),
    'blue' => const Color(0xFFE3F0FA),
    'purple' => const Color(0xFFECE5F7),
    'pink' => const Color(0xFFFFE7F0),
    'brown' => const Color(0xFFF1E7E2),
    'gray' => const Color(0xFFEDEDED),
    _ => p.surface,
  };
}

class _CollectionsSheet extends StatefulWidget {
  final BeBlogNotesRepository repository;
  final List<NoteFolderDto> folders;
  final List<NoteLabelDto> labels;

  const _CollectionsSheet({
    required this.repository,
    required this.folders,
    required this.labels,
  });

  @override
  State<_CollectionsSheet> createState() => _CollectionsSheetState();
}

class _CollectionsSheetState extends State<_CollectionsSheet> {
  late List<NoteFolderDto> _folders;
  late List<NoteLabelDto> _labels;

  @override
  void initState() {
    super.initState();
    _folders = [...widget.folders];
    _labels = [...widget.labels];
  }

  Future<String?> _askName(String title) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 200,
          decoration: const InputDecoration(hintText: 'Tên'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _addFolder() async {
    final name = await _askName('Thư mục mới');
    if (name == null || name.isEmpty) return;
    final result = await widget.repository.createFolder(name: name);
    if (!mounted || result.data == null) return;
    setState(() => _folders.add(result.data!));
  }

  Future<void> _addLabel() async {
    final name = await _askName('Nhãn mới');
    if (name == null || name.isEmpty) return;
    final result = await widget.repository.createLabel(name: name);
    if (!mounted || result.data == null) return;
    setState(() => _labels.add(result.data!));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageX,
          0,
          AppSpacing.pageX,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                Text(
                  context.t('notes.folders'),
                  style: AppTypography.sectionTitle(context),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addFolder,
                  icon: Icon(Icons.add, color: p.foreground),
                ),
              ],
            ),
            if (_folders.isEmpty)
              Text(
                context.t('notes.noFolder'),
                style: AppTypography.body(context),
              ),
            ..._folders.map(
              (folder) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.folder_outlined, color: p.muted),
                title: Text(
                  folder.name,
                  style: AppTypography.body(context, color: p.foreground),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: p.muted),
                  onPressed: () async {
                    final result = await widget.repository.deleteFolder(
                      folder.id,
                    );
                    if (result.success && mounted) {
                      setState(() => _folders.remove(folder));
                    }
                  },
                ),
              ),
            ),
            Divider(height: 32, color: p.border),
            Row(
              children: [
                Text(
                  context.t('notes.labels'),
                  style: AppTypography.sectionTitle(context),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addLabel,
                  icon: Icon(Icons.add, color: p.foreground),
                ),
              ],
            ),
            if (_labels.isEmpty)
              Text(
                context.t('notes.noLabels'),
                style: AppTypography.body(context),
              ),
            ..._labels.map(
              (label) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.label_outline, color: p.muted),
                title: Text(
                  label.name,
                  style: AppTypography.body(context, color: p.foreground),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: p.muted),
                  onPressed: () async {
                    final result = await widget.repository.deleteLabel(
                      label.id,
                    );
                    if (result.success && mounted) {
                      setState(() => _labels.remove(label));
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
