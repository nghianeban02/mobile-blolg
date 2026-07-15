class BookReviewResponse {
  final bool success;
  final String? message;

  BookReviewResponse({required this.success, this.message});

  factory BookReviewResponse.fromJson(Map<String, dynamic> json) {
    return BookReviewResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] ?? json['error'],
    );
  }
}
