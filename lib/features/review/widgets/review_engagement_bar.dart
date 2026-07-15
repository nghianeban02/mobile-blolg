import 'package:flutter/material.dart';
import 'package:mobile/features/social/models/discussion_target.dart';
import 'package:mobile/features/social/widgets/engagement_like_bar.dart';

/// Like review — wrapper quanh [EngagementLikeBar].
class ReviewEngagementBar extends StatelessWidget {
  final String reviewId;

  const ReviewEngagementBar({super.key, required this.reviewId});

  @override
  Widget build(BuildContext context) {
    return EngagementLikeBar(
      target: DiscussionTarget.review,
      targetId: reviewId,
    );
  }
}
