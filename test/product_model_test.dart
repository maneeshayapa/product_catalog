import 'package:flutter_test/flutter_test.dart';
import 'package:product_catalog/data/models/product.dart';

void main() {
  test('parses product details and customer reviews from JSON', () {
    final product = Product.fromJson({
      'id': 42,
      'title': 'Sample product',
      'description': 'A sample description',
      'price': 25,
      'rating': 4.25,
      'stock': 7,
      'thumbnail': 'https://example.com/image.png',
      'images': ['https://example.com/image-2.png'],
      'brand': 'Sample brand',
      'category': 'sample-category',
      'discountPercentage': 12.5,
      'availabilityStatus': 'Low Stock',
      'warrantyInformation': 'One year warranty',
      'shippingInformation': 'Ships in three days',
      'returnPolicy': '30-day returns',
      'reviews': [
        {
          'rating': 5,
          'comment': 'Works well',
          'date': '2025-01-15T10:00:00.000Z',
          'reviewerName': 'Alex',
          'reviewerEmail': 'alex@example.com',
        },
      ],
    });

    expect(product.brand, 'Sample brand');
    expect(product.category, 'sample-category');
    expect(product.discountPercentage, 12.5);
    expect(product.availabilityStatus, 'Low Stock');
    expect(product.warrantyInformation, 'One year warranty');
    expect(product.shippingInformation, 'Ships in three days');
    expect(product.returnPolicy, '30-day returns');
    expect(product.reviews, hasLength(1));
    expect(product.reviews.single.reviewerName, 'Alex');
    expect(product.reviews.single.rating, 5);
    expect(product.reviews.single.date, DateTime.utc(2025, 1, 15, 10));

    final restored = Product.fromJson(product.toJson());
    expect(restored.toJson(), product.toJson());
  });

  test('safely defaults missing optional fields and invalid reviews', () {
    final product = Product.fromJson({
      'id': 1,
      'title': 'Legacy cart product',
      'description': '',
      'price': 10,
      'rating': 3,
      'stock': 2,
      'thumbnail': '',
      'images': [],
      'brand': null,
      'category': 7,
      'discountPercentage': 'unknown',
      'reviews': null,
    });

    expect(product.brand, isNull);
    expect(product.category, isNull);
    expect(product.discountPercentage, isNull);
    expect(product.availabilityStatus, isNull);
    expect(product.reviews, isEmpty);
  });
}
