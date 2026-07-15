import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/models/productivity_dtos.dart';
import 'package:mobile/data/repositories/notes_repository.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final String? initialFolderId;

  const NoteEditorScreen({super.key, this.noteId, this.initialFolderId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _repository = BeBlogNotesRepository();
  final _title = TextEditingController();
  final _content = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _pinned = false;
  bool _archived = false;
  String _color = 'default';
  String? _folderId;
  String? _error;
  List<NoteFolderDto> _folders = const [];
  List<NoteLabelDto> _labels = const [];
  Set<String> _selectedLabelIds = {};

  static const _colors = <String, Color>{
    'default': Colors.white,
    'red': Color(0xFFFFE8E5),
    'orange': Color(0xFFFFEBD9),
    'yellow': Color(0xFFFFF5CC),
    'green': Color(0xFFE3F4E8),
    'blue': Color(0xFFE3F0FA),
    'purple': Color(0xFFECE5F7),
    'pink': Color(0xFFFFE7F0),
    'brown': Color(0xFFF1E7E2),
    'gray': Color(0xFFEDEDED),
  };

  @override
  void initState() {
    super.initState();
    _folderId = widget.initialFolderId;
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final folderResult = await _repository.getFolders();
    final labelResult = await _repository.getLabels();
    final noteResult = widget.noteId == null
        ? null
        : await _repository.getOne(widget.noteId!);
    if (!mounted) return;

    final note = noteResult?.data;
    setState(() {
      _loading = false;
      _folders = folderResult.data ?? const [];
      _labels = labelResult.data ?? const [];
      if (note != null) {
        _title.text = note.title;
        // Rich TipTap JSON is edited as its backend-provided plain-text mirror.
        _content.text = note.contentFormat == 'plain'
            ? note.content
            : (note.preview.isNotEmpty ? note.preview : note.content);
        _pinned = note.pinned;
        _archived = note.archived;
        _color = _colors.containsKey(note.color) ? note.color : 'default';
        _folderId = note.folderId;
        _selectedLabelIds = note.labels.map((label) => label.id).toSet();
      }
      if (widget.noteId != null && note == null) {
        _error = noteResult?.message ?? 'Không tải được ghi chú.';
      }
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty && _content.text.trim().isEmpty) {
      setState(() => _error = 'Hãy nhập tiêu đề hoặc nội dung.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final request = NoteWriteRequest(
      title: _title.text,
      content: _content.text,
      color: _color,
      folderId: _folderId,
      pinned: _pinned,
      archived: _archived,
      labelIds: _selectedLabelIds.toList(),
    );
    final result = widget.noteId == null
        ? await _repository.create(request)
        : await _repository.update(widget.noteId!, request);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!result.success) {
      setState(() => _error = result.message ?? 'Không lưu được ghi chú.');
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _colors[_color],
    appBar: AppBar(
      backgroundColor: _colors[_color],
      title: Text(widget.noteId == null ? 'Ghi chú mới' : 'Chỉnh sửa ghi chú'),
      actions: [
        IconButton(
          tooltip: _pinned ? 'Bỏ ghim' : 'Ghim',
          onPressed: () => setState(() => _pinned = !_pinned),
          icon: Icon(_pinned ? Icons.push_pin : Icons.push_pin_outlined),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('LƯU'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBrown),
          )
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _title,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Tiêu đề',
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _content,
                    minLines: 14,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 16, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Bắt đầu viết…',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('MÀU THẺ', style: _sectionStyle()),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colors.entries
                        .map(
                          (entry) => InkWell(
                            onTap: () => setState(() => _color = entry.key),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: entry.value,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == entry.key
                                      ? AppColors.primaryBrown
                                      : Colors.black12,
                                  width: _color == entry.key ? 3 : 1,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (_folders.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String?>(
                      initialValue: _folderId,
                      decoration: const InputDecoration(labelText: 'Thư mục'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Không có thư mục'),
                        ),
                        ..._folders.map(
                          (folder) => DropdownMenuItem<String?>(
                            value: folder.id,
                            child: Text(
                              '${folder.icon ?? '📁'} ${folder.name}',
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _folderId = value),
                    ),
                  ],
                  if (_labels.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('NHÃN', style: _sectionStyle()),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _labels
                          .map(
                            (label) => FilterChip(
                              label: Text(label.name),
                              selected: _selectedLabelIds.contains(label.id),
                              onSelected: (selected) => setState(() {
                                if (selected) {
                                  _selectedLabelIds.add(label.id);
                                } else {
                                  _selectedLabelIds.remove(label.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Lưu vào kho lưu trữ'),
                    value: _archived,
                    onChanged: (value) => setState(() => _archived = value),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
  );

  TextStyle _sectionStyle() => GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.4,
    color: AppColors.homeTextLight,
  );
}
