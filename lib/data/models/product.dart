import 'product_review.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;
  final List<String> images;
  final String? brand;
  final String? category;
  final double? discountPercentage;
  final String? availabilityStatus;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? returnPolicy;
  final List<ProductReview> reviews;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    required this.images,
    this.brand,
    this.category,
    this.discountPercentage,
    this.availabilityStatus,
    this.warrantyInformation,
    this.shippingInformation,
    this.returnPolicy,
    this.reviews = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'stock': stock,
      'thumbnail': thumbnail,
      'images': images,
      'brand': brand,
      'category': category,
      'discountPercentage': discountPercentage,
      'availabilityStatus': availabilityStatus,
      'warrantyInformation': warrantyInformation,
      'shippingInformation': shippingInformation,
      'returnPolicy': returnPolicy,
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'];

    return Product(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      stock: json['stock'],
      thumbnail: json['thumbnail'],
      images: List<String>.from(json['images'] ?? []),
      brand: json['brand'] is String ? json['brand'] as String : null,
      category: json['category'] is String ? json['category'] as String : null,
      discountPercentage: json['discountPercentage'] is num
          ? (json['discountPercentage'] as num).toDouble()
          : null,
      availabilityStatus: json['availabilityStatus'] is String
          ? json['availabilityStatus'] as String
          : null,
      warrantyInformation: json['warrantyInformation'] is String
          ? json['warrantyInformation'] as String
          : null,
      shippingInformation: json['shippingInformation'] is String
          ? json['shippingInformation'] as String
          : null,
      returnPolicy: json['returnPolicy'] is String
          ? json['returnPolicy'] as String
          : null,
      reviews: rawReviews is List
          ? rawReviews
                .whereType<Map>()
                .map(
                  (review) =>
                      ProductReview.fromJson(Map<String, dynamic>.from(review)),
                )
                .toList()
          : const [],
    );
  }
}
