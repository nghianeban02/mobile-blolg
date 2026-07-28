import 'package:flutter/material.dart';
import 'package:mobile/core/widgets/editorial_states.dart';

/// Loading / lỗi inline — wraps shared editorial empty/error/skeleton.
class AsyncLoadingView extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const AsyncLoadingView({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const EditorialFeedSkeleton(count: 2);
    }
    if (errorMessage == null) return const SizedBox.shrink();
    return EditorialErrorState(message: errorMessage!, onRetry: onRetry);
  }
}
