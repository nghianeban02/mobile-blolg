import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/data/repositories/engagement_repository.dart';
import 'package:mobile/features/reading_list/screens/my_reading_list_screen.dart';

class ReadingStreakBox extends StatefulWidget {
  const ReadingStreakBox({super.key});

  @override
  State<ReadingStreakBox> createState() => _ReadingStreakBoxState();
}

class _ReadingStreakBoxState extends State<ReadingStreakBox> {
  final _engagementRepo = BeBlogEngagementRepository();

  int _current = 0;
  int _longest = 0;
  List<bool> _days = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _engagementRepo.getStreak();
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _current = result.data?.currentStreak ?? 0;
      _longest = result.data?.longestStreak ?? 0;
      _days =
          result.data?.last7Days.map((day) => day.active).toList() ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final label = !_loaded
        ? '—'
        : _current == 0
        ? 'Bắt đầu hôm nay'
        : '$_current ngày liên tiếp';

    return Material(
      color: const Color(0xFF6E7E66),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyReadingListScreen()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'READING STREAK',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 36,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_days.isNotEmpty) ...[
                Row(
                  children: _days
                      .map(
                        (active) => Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? Colors.white : Colors.white24,
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                'Kỷ lục: $_longest ngày · Chạm để mở danh sách đang đọc.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
