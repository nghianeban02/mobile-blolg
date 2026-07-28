import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_palette.dart';
import 'package:mobile/core/widgets/editorial_button.dart';
import 'package:mobile/features/posts/screens/create_post_screen.dart';
import 'package:mobile/features/review/screens/create_book_review_screen.dart';

/// Home write CTA + menu — mirror web `HomeWriteMenu`.
class HomeWriteMenu extends StatelessWidget {
  const HomeWriteMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return EditorialButton(
      label: context.t('home.write'),
      expanded: true,
      trailing: Text(
        '▾',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      onPressed: () async {
        final choice = await showModalBottomSheet<String>(
          context: context,
          backgroundColor: p.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(
                        context.t('home.writeReview'),
                        style: TextStyle(
                          color: p.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, 'review'),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      title: Text(
                        context.t('home.newPost'),
                        style: TextStyle(
                          color: p.foreground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, 'post'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        if (!context.mounted || choice == null) return;
        if (choice == 'review') {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const CreateBookReviewScreen(),
            ),
          );
        } else if (choice == 'post') {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CreatePostScreen()),
          );
        }
      },
    );
  }
}
