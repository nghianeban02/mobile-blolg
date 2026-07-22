import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/widgets/editorial_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Nút chia sẻ — parity `web-blog/components/social/share-button.tsx`.
class ShareButton extends StatelessWidget {
  final String? title;
  final String url;
  final bool outline;

  const ShareButton({
    super.key,
    required this.url,
    this.title,
    this.outline = true,
  });

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = context.t('common.linkCopied');
    final failed = context.t('common.shareFailed');
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: title == null || title!.isEmpty ? url : '$title\n$url',
          subject: title,
        ),
      );
    } catch (_) {
      try {
        await Clipboard.setData(ClipboardData(text: url));
        messenger?.showSnackBar(SnackBar(content: Text(copied)));
      } catch (_) {
        messenger?.showSnackBar(SnackBar(content: Text(failed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EditorialPillButton(
      label: context.t('common.share'),
      outline: outline,
      icon: Icons.ios_share_rounded,
      onPressed: () => _share(context),
    );
  }
}
