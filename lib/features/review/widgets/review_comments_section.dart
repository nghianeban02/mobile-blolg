import 'package:flutter/material.dart';
import 'package:mobile/features/social/models/discussion_target.dart';
import 'package:mobile/features/social/widgets/discussion_comments_section.dart';

/// Bình luận review — wrapper quanh [DiscussionCommentsSection].
class ReviewCommentsSection extends StatelessWidget {
  final String reviewId;

  const ReviewCommentsSection({super.key, required this.reviewId});

  @override
  Widget build(BuildContext context) {
    return DiscussionCommentsSection(
      target: DiscussionTarget.review,
      targetId: reviewId,
    );
  }
}
