import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/utils/format_datetime.dart';
import 'package:mobile/core/widgets/editorial_confirm_dialog.dart';
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
    if (changed == true) _load();
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
    _load();
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
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.homeBackground,
    appBar: AppBar(
      title: const Text('Ghi chú'),
      actions: [
        IconButton(
          tooltip: 'Thư mục & nhãn',
          onPressed: _manageCollections,
          icon: const Icon(Icons.folder_copy_outlined),
        ),
        if (_tab == _NotesTab.trash && _notes.isNotEmpty)
          IconButton(
            tooltip: 'Dọn sạch thùng rác',
            onPressed: _emptyTrash,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
    ),
    floatingActionButton: _tab == _NotesTab.active
        ? FloatingActionButton(
            onPressed: _openEditor,
            backgroundColor: AppColors.primaryBrown,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          )
        : null,
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Tìm trong ghi chú…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _search.clear,
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_NotesTab>(
            segments: [
              ButtonSegment(
                value: _NotesTab.active,
                label: Text('Tất cả (${_stats.active})'),
                icon: const Icon(Icons.notes),
              ),
              ButtonSegment(
                value: _NotesTab.archived,
                label: Text('Lưu trữ (${_stats.archived})'),
                icon: const Icon(Icons.archive_outlined),
              ),
              ButtonSegment(
                value: _NotesTab.trash,
                label: Text('Rác (${_stats.trashed})'),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
            selected: {_tab},
            showSelectedIcon: false,
            style: const ButtonStyle(
              shape: WidgetStatePropertyAll(StadiumBorder()),
            ),
            onSelectionChanged: (value) {
              setState(() => _tab = value.first);
              _load();
            },
          ),
          if (_tab == _NotesTab.active && _folders.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả thư mục'),
                    shape: const StadiumBorder(),
                    selected: _folderId == null,
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
                        label: Text('${folder.icon ?? '📁'} ${folder.name}'),
                        shape: const StadiumBorder(),
                        selected: _folderId == folder.id,
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
          ],
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryBrown),
              ),
            )
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _load)
          else if (_notes.isEmpty)
            const _EmptyState()
          else
            ..._notes.map(
              (note) => _NoteCard(
                note: note,
                tab: _tab,
                onOpen: () => _openEditor(note),
                onPin: () => _runAction(() => _repository.togglePin(note.id)),
                onArchive: () => _runAction(
                  () => note.archived
                      ? _repository.unarchive(note.id)
                      : _repository.archive(note.id),
                ),
                onDuplicate: () => _runAction(
                  () => _repository.duplicate(note.id),
                  success: 'Đã nhân bản ghi chú.',
                ),
                onRestore: () => _runAction(() => _repository.restore(note.id)),
                onDelete: () =>
                    _deleteNote(note, permanent: _tab == _NotesTab.trash),
              ),
            ),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: _noteColor(note.color),
    elevation: note.pinned ? 2 : 0,
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
                child: Text(note.icon!, style: const TextStyle(fontSize: 22)),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (note.pinned) ...[
                        const Icon(
                          Icons.push_pin,
                          size: 14,
                          color: AppColors.primaryBrown,
                        ),
                        const SizedBox(width: 5),
                      ],
                      Expanded(
                        child: Text(
                          note.title.isEmpty
                              ? 'Ghi chú không tiêu đề'
                              : note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                          ),
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.homeTextLight,
                      ),
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
                              shape: const StadiumBorder(
                                side: BorderSide(color: AppColors.border),
                              ),
                              label: Text(
                                label.name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    '${note.wordCount} từ · ${formatCommentDateTime(note.lastEditedAt ?? note.updatedAt ?? note.createdAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.homeTextLight,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
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
                    child: Text(note.pinned ? 'Bỏ ghim' : 'Ghim'),
                  ),
                  const PopupMenuItem(value: 'archive', child: Text('Lưu trữ')),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Nhân bản'),
                  ),
                ],
                if (tab == _NotesTab.archived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: Text('Bỏ lưu trữ'),
                  ),
                if (tab == _NotesTab.trash)
                  const PopupMenuItem(
                    value: 'restore',
                    child: Text('Khôi phục'),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    tab == _NotesTab.trash
                        ? 'Xóa vĩnh viễn'
                        : 'Chuyển vào thùng rác',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Color _noteColor(String name) => switch (name) {
    'red' => const Color(0xFFFFE8E5),
    'orange' => const Color(0xFFFFEBD9),
    'yellow' => const Color(0xFFFFF5CC),
    'green' => const Color(0xFFE3F4E8),
    'blue' => const Color(0xFFE3F0FA),
    'purple' => const Color(0xFFECE5F7),
    'pink' => const Color(0xFFFFE7F0),
    'brown' => const Color(0xFFF1E7E2),
    'gray' => const Color(0xFFEDEDED),
    _ => Colors.white,
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
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Text('Thư mục', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: _addFolder, icon: const Icon(Icons.add)),
            ],
          ),
          if (_folders.isEmpty) const Text('Chưa có thư mục.'),
          ..._folders.map(
            (folder) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: Text(folder.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
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
          const Divider(height: 32),
          Row(
            children: [
              Text('Nhãn', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: _addLabel, icon: const Icon(Icons.add)),
            ],
          ),
          if (_labels.isEmpty) const Text('Chưa có nhãn.'),
          ..._labels.map(
            (label) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.label_outline),
              title: Text(label.name),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final result = await widget.repository.deleteLabel(label.id);
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        Icon(Icons.note_alt_outlined, size: 48, color: AppColors.homeTextLight),
        SizedBox(height: 12),
        Text('Chưa có ghi chú trong mục này.'),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    ),
  );
}
