import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/data/data.dart';

/// Interactive samples calling **be-blog** controllers (`/api/posts`, `/api/books`, …).
///
/// Đổi [ApiConstants.baseUrl] cho đúng host/port (Android Emulator: `10.0.2.2`).
class ApiDemoScreen extends StatefulWidget {
  const ApiDemoScreen({super.key});

  @override
  State<ApiDemoScreen> createState() => _ApiDemoScreenState();
}

class _ApiDemoScreenState extends State<ApiDemoScreen> {
  final _postsRepo = BeBlogPostsRepository();
  final _booksRepo = BeBlogBooksRepository();
  final _reviewsRepo = BeBlogReviewsRepository();
  final _catalogRepo = BeBlogCatalogRepository();
  final _usersRepo = BeBlogUsersRepository();
  final _readingRepo = BeBlogReadingListRepository();
  final _commentsRepo = BeBlogCommentsRepository();
  final _likesRepo = BeBlogLikesRepository();
  final _authRepo = AuthRepository();

  final _registerUsername = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _loginUsername = TextEditingController(text: 'admin@123');
  final _loginPassword = TextEditingController(text: 'admin123');
  final _postTitle = TextEditingController();
  final _postContent = TextEditingController();
  final _reviewIdController = TextEditingController();

  bool _busyPosts = false;
  bool _busyLogin = false;
  bool _busyCreatePost = false;
  bool _busyBooks = false;
  bool _busyReviews = false;
  bool _busyCatalog = false;
  bool _busyMe = false;
  bool _busyReading = false;
  bool _busyComments = false;
  bool _busyLikeCount = false;
  bool _busyRegister = false;

  String _logPosts = '—';
  String _logLogin = '—';
  String _logCreatePost = '—';
  String _logBooks = '—';
  String _logReviews = '—';
  String _logCatalog = '—';
  String _logMe = '—';
  String _logReading = '—';
  String _logComments = '—';
  String _logLikeCount = '—';
  String _logRegister = '—';

  @override
  void dispose() {
    _registerUsername.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _postTitle.dispose();
    _postContent.dispose();
    _reviewIdController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    setState(() {
      _busyLogin = true;
      _logLogin = 'Đang gửi POST /api/auth/login…';
    });
    final result = await _authRepo.login(
      LoginRequest(
        email: _loginUsername.text.trim(),
        password: _loginPassword.text,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busyLogin = false;
      _logLogin = result.success
          ? 'OK — JWT đã lưu (SharedPreferences).'
          : 'Lỗi: ${result.message ?? '—'}';
    });
  }

  Future<void> _createPost() async {
    final title = _postTitle.text.trim();
    final content = _postContent.text.trim();
    if (title.isEmpty || content.isEmpty) {
      setState(() => _logCreatePost = 'Nhập title và content.');
      return;
    }

    setState(() {
      _busyCreatePost = true;
      _logCreatePost = 'Kiểm tra quyền admin…';
    });

    final me = await _usersRepo.me();
    if (!mounted) return;
    if (!me.success || me.data == null) {
      setState(() {
        _busyCreatePost = false;
        _logCreatePost =
            'HTTP ${me.statusCode}: cần đăng nhập JWT trước (admin@123 / admin123).';
      });
      return;
    }
    if (!me.data!.isAdmin) {
      setState(() {
        _busyCreatePost = false;
        _logCreatePost =
            'Tài khoản ${me.data!.username} không có ROLE_ADMIN — chỉ admin được POST /api/posts.';
      });
      return;
    }

    setState(() => _logCreatePost = 'Đang gửi POST /api/posts (multipart)…');
    final r = await _postsRepo.createMultipart(title: title, content: content);
    if (!mounted) return;
    setState(() {
      _busyCreatePost = false;
      if (r.success && r.data != null) {
        final p = r.data!;
        _logCreatePost =
            'HTTP ${r.statusCode} — tạo post OK.\nid: ${p.id}\ntitle: ${p.title}';
        _postTitle.clear();
        _postContent.clear();
      } else {
        _logCreatePost =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadPosts() async {
    setState(() {
      _busyPosts = true;
      _logPosts = 'Đang tải…';
    });
    final r = await _postsRepo.getAll();
    if (!mounted) return;
    setState(() {
      _busyPosts = false;
      if (r.success && r.data != null) {
        final list = r.data!;
        _logPosts =
            'HTTP ${r.statusCode} — ${list.length} bài.\n${list.take(5).map((p) => '• ${p.title}').join('\n')}';
      } else {
        _logPosts =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadBooks() async {
    setState(() {
      _busyBooks = true;
      _logBooks = 'Đang tải…';
    });
    final r = await _booksRepo.getAll();
    if (!mounted) return;
    setState(() {
      _busyBooks = false;
      if (r.success && r.data != null) {
        final list = r.data!;
        _logBooks =
            'HTTP ${r.statusCode} — ${list.length} sách.\n${list.take(5).map((b) => '• ${b.title}').join('\n')}';
      } else {
        _logBooks =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadReviews() async {
    setState(() {
      _busyReviews = true;
      _logReviews = 'Đang tải…';
    });
    final r = await _reviewsRepo.getAll();
    if (!mounted) return;
    setState(() {
      _busyReviews = false;
      if (r.success && r.data != null) {
        final list = r.data!;
        _logReviews =
            'HTTP ${r.statusCode} — ${list.length} review.\n${list.take(5).map((v) => '• ${v.title} (${v.rating}★)').join('\n')}';
      } else {
        _logReviews =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _busyCatalog = true;
      _logCatalog = 'Đang tải tags / genres / authors…';
    });
    final tags = await _catalogRepo.getTags();
    final genres = await _catalogRepo.getGenres();
    final authors = await _catalogRepo.getAuthors();
    if (!mounted) return;
    setState(() {
      _busyCatalog = false;
      final ok = tags.success && genres.success && authors.success;
      if (ok) {
        _logCatalog =
            'tags: ${tags.data?.length ?? 0}, genres: ${genres.data?.length ?? 0}, authors: ${authors.data?.length ?? 0}';
      } else {
        _logCatalog =
            'tags ${tags.statusCode}, genres ${genres.statusCode}, authors ${authors.statusCode}';
      }
    });
  }

  Future<void> _loadMe() async {
    setState(() {
      _busyMe = true;
      _logMe = 'Đang gọi GET /api/users/me…';
    });
    final r = await _usersRepo.me();
    if (!mounted) return;
    setState(() {
      _busyMe = false;
      if (r.success && r.data != null) {
        final u = r.data!;
        _logMe =
            'HTTP ${r.statusCode}\nusername: ${u.username}\nemail: ${u.email ?? '—'}';
      } else {
        _logMe =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''} (cần đăng nhập JWT)';
      }
    });
  }

  Future<void> _loadReadingList() async {
    setState(() {
      _busyReading = true;
      _logReading = 'Đang gọi GET /api/reading-list/me…';
    });
    final r = await _readingRepo.getMine();
    if (!mounted) return;
    setState(() {
      _busyReading = false;
      if (r.success && r.data != null) {
        _logReading =
            'HTTP ${r.statusCode} — ${r.data!.length} mục reading list.';
      } else {
        _logReading =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadCommentsForReview() async {
    final id = _reviewIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _logComments = 'Nhập review UUID vào ô bên dưới.');
      return;
    }
    setState(() {
      _busyComments = true;
      _logComments = 'Đang tải comments…';
    });
    final r = await _commentsRepo.listByReview(id);
    if (!mounted) return;
    setState(() {
      _busyComments = false;
      if (r.success && r.data != null) {
        _logComments =
            'HTTP ${r.statusCode} — ${r.data!.length} comment.\n${r.data!.take(4).map((c) {
              final t = c.content;
              final short = t.length <= 60 ? t : '${t.substring(0, 60)}…';
              return '• $short';
            }).join('\n')}';
      } else {
        _logComments =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _loadLikeCount() async {
    final id = _reviewIdController.text.trim();
    if (id.isEmpty) {
      setState(() => _logLikeCount = 'Nhập review UUID.');
      return;
    }
    setState(() {
      _busyLikeCount = true;
      _logLikeCount = 'Đang đếm likes…';
    });
    final r = await _likesRepo.count(id);
    if (!mounted) return;
    setState(() {
      _busyLikeCount = false;
      if (r.success) {
        _logLikeCount = 'HTTP ${r.statusCode} — count = ${r.data}';
      } else {
        _logLikeCount =
            'HTTP ${r.statusCode}${r.message != null ? ': ${r.message}' : ''}';
      }
    });
  }

  Future<void> _submitRegister() async {
    setState(() {
      _busyRegister = true;
      _logRegister = 'Đang gửi POST /api/auth/register…';
    });
    final result = await _authRepo.register(
      RegisterRequest(
        username: _registerUsername.text.trim(),
        email: _registerEmail.text.trim(),
        password: _registerPassword.text,
      ),
    );
    if (!mounted) return;
    setState(() {
      _busyRegister = false;
      _logRegister =
          '${result.success ? 'OK' : 'Lỗi'}: ${result.message ?? '—'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        foregroundColor: AppColors.homeTextDark,
        elevation: 0,
        title: Text(
          'be-blog API',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: AppColors.homeTextDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Base URL\n${ApiConstants.baseUrl}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.homeTextDark.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Repo mẫu: BeBlogPostsRepository, … — xem `lib/data/`.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.homeTextLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Public reads'),
          _actionRow(
            label: 'GET /api/posts',
            busy: _busyPosts,
            onPressed: _loadPosts,
          ),
          _mono(_logPosts),
          const SizedBox(height: 20),
          _sectionTitle('Admin — POST /api/posts'),
          Text(
            'Chỉ tài khoản ROLE_ADMIN (mặc định: admin@123 / admin123). Đăng nhập trước khi tạo post.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.homeTextLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _loginUsername,
            decoration: const InputDecoration(labelText: 'Username (admin)'),
          ),
          TextField(
            controller: _loginPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busyLogin ? null : _submitLogin,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
            ),
            child: Text(_busyLogin ? '…' : 'POST /api/auth/login'),
          ),
          _mono(_logLogin),
          const SizedBox(height: 8),
          TextField(
            controller: _postTitle,
            decoration: const InputDecoration(labelText: 'Post title'),
          ),
          TextField(
            controller: _postContent,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Post content'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busyCreatePost ? null : _createPost,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBrown,
            ),
            child: Text(_busyCreatePost ? '…' : 'POST /api/posts'),
          ),
          _mono(_logCreatePost),
          _actionRow(
            label: 'GET /api/books',
            busy: _busyBooks,
            onPressed: _loadBooks,
          ),
          _mono(_logBooks),
          _actionRow(
            label: 'GET /api/reviews',
            busy: _busyReviews,
            onPressed: _loadReviews,
          ),
          _mono(_logReviews),
          _actionRow(
            label: 'GET tags + genres + authors',
            busy: _busyCatalog,
            onPressed: _loadCatalog,
          ),
          _mono(_logCatalog),
          const SizedBox(height: 20),
          _sectionTitle('Review UUID (comments & likes)'),
          TextField(
            controller: _reviewIdController,
            decoration: const InputDecoration(
              hintText: 'Paste review UUID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busyComments ? null : _loadCommentsForReview,
                  child: const Text('Comments'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busyLikeCount ? null : _loadLikeCount,
                  child: const Text('Like count'),
                ),
              ),
            ],
          ),
          _mono('Comments:\n$_logComments'),
          _mono('Likes:\n$_logLikeCount'),
          const SizedBox(height: 20),
          _sectionTitle('JWT (đăng nhập trước)'),
          _actionRow(
            label: 'GET /api/users/me',
            busy: _busyMe,
            onPressed: _loadMe,
          ),
          _mono(_logMe),
          _actionRow(
            label: 'GET /api/reading-list/me',
            busy: _busyReading,
            onPressed: _loadReadingList,
          ),
          _mono(_logReading),
          const SizedBox(height: 20),
          _sectionTitle('POST /api/auth/register'),
          TextField(
            controller: _registerUsername,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _registerEmail,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _registerPassword,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busyRegister ? null : _submitRegister,
            child: Text(_busyRegister ? '…' : 'Register'),
          ),
          _mono(_logRegister),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppColors.homeTextLight,
        ),
      ),
    );
  }

  Widget _actionRow({
    required String label,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBrown,
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label, style: GoogleFonts.inter(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mono(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: SelectableText(
        text,
        style: GoogleFonts.robotoMono(fontSize: 11, height: 1.35),
      ),
    );
  }
}
