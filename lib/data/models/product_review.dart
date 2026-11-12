class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
    required this.reviewerEmail,
  });

  final int rating;
  final String comment;
  final DateTime? date;
  final String reviewerName;
  final String reviewerEmail;

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'];
    final rawDate = json['date'];

    return ProductReview(
      rating: rawRating is num ? rawRating.round() : 0,
      comment: json['comment'] is String ? json['comment'] as String : '',
      date: rawDate is String ? DateTime.tryParse(rawDate) : null,
      reviewerName: json['reviewerName'] is String
          ? json['reviewerName'] as String
          : '',
      reviewerEmail: json['reviewerEmail'] is String
          ? json['reviewerEmail'] as String
          : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'date': date?.toIso8601String(),
      'reviewerName': reviewerName,
      'reviewerEmail': reviewerEmail,
    };
  }
}
