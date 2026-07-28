import 'package:flutter/material.dart';
import 'package:mobile/core/i18n/locale_controller.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/widgets/editorial_page_header.dart';

/// Library page header — mirror web `/library` PageHeader.
class ReadingHeader extends StatelessWidget {
  const ReadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageX,
        8,
        AppSpacing.pageX,
        0,
      ),
      child: EditorialPageHeader(
        title: context.t('library.title'),
        subtitle: context.t('library.mySubtitle'),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
