import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/product.dart';
import '../../data/models/product_review.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../cart/cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final List<String> _galleryImages;
  late String _selectedImage;
  List<Product> _relatedProducts = [];
  bool _isLoadingRelated = true;
  String? _relatedProductsError;

  @override
  void initState() {
    super.initState();
    _galleryImages = <String>{
      widget.product.thumbnail,
      ...widget.product.images,
    }.where((image) => image.trim().isNotEmpty).toList();
    _selectedImage = _galleryImages.isEmpty ? '' : _galleryImages.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRelatedProducts();
    });
  }

  Future<void> _loadRelatedProducts() async {
    final category = widget.product.category?.trim();
    if (category == null || category.isEmpty) {
      if (mounted) setState(() => _isLoadingRelated = false);
      return;
    }

    setState(() {
      _isLoadingRelated = true;
      _relatedProductsError = null;
    });
    try {
      final products = await context
          .read<ProductProvider>()
          .fetchRelatedProducts(
            category: category,
            excludeProductId: widget.product.id,
          );
      if (!mounted) return;
      setState(() {
        _relatedProducts = products;
        _isLoadingRelated = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _relatedProductsError = 'Could not load related products.';
        _isLoadingRelated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = (constraints.maxWidth * 0.78)
              .clamp(240.0, 420.0)
              .toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _ProductImage(
                        key: ValueKey(_selectedImage),
                        imageUrl: _selectedImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (_galleryImages.length > 1) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _galleryImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final image = _galleryImages[index];
                            final isSelected = image == _selectedImage;
                            return InkWell(
                              onTap: () => setState(() {
                                _selectedImage = image;
                              }),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 76,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.primary
                                        : Colors.black12,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _ProductImage(
                                    imageUrl: image,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    if (product.brand != null || product.category != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (product.brand != null &&
                              product.brand!.trim().isNotEmpty)
                            _InfoChip(
                              icon: Icons.storefront_outlined,
                              iconColor: colors.primary,
                              label: product.brand!,
                            ),
                          if (product.category != null &&
                              product.category!.trim().isNotEmpty)
                            _InfoChip(
                              icon: Icons.category_outlined,
                              iconColor: colors.primary,
                              label: product.category!,
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _InfoChip(
                          icon: Icons.star_rounded,
                          iconColor: colors.tertiary,
                          label:
                              '${product.rating.toStringAsFixed(1)} · ${product.reviews.length} reviews',
                        ),
                        _InfoChip(
                          icon: product.stock > 0
                              ? Icons.inventory_2_outlined
                              : Icons.remove_shopping_cart_outlined,
                          iconColor: product.stock > 0
                              ? colors.primary
                              : colors.error,
                          label: [
                            if (product.availabilityStatus != null &&
                                product.availabilityStatus!.trim().isNotEmpty)
                              product.availabilityStatus!,
                            '${product.stock} in stock',
                          ].join(' · '),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (product.discountPercentage != null &&
                            product.discountPercentage! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${product.discountPercentage!.toStringAsFixed(0)}% OFF',
                              style: TextStyle(
                                color: colors.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ProductInformation(
                      warranty: product.warrantyInformation,
                      shipping: product.shippingInformation,
                      returns: product.returnPolicy,
                    ),
                    const SizedBox(height: 28),
                    _CustomerReviews(product: product),
                    const SizedBox(height: 28),
                    _RelatedProductsSection(
                      products: _relatedProducts,
                      isLoading: _isLoadingRelated,
                      errorMessage: _relatedProductsError,
                      onRetry: _loadRelatedProducts,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.stock <= 0) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'This product is out of stock and cannot be added.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: product.stock <= 0
                    ? null
                    : () async {
                        final result = await context
                            .read<CartProvider>()
                            .addToCart(product);
                        if (!context.mounted) return;

                        final messenger = ScaffoldMessenger.of(context);
                        if (result != CartOperationResult.success) {
                          final message = switch (result) {
                            CartOperationResult.outOfStock =>
                              'This product is out of stock.',
                            CartOperationResult.stockLimitReached =>
                              'You have reached the available stock limit.',
                            CartOperationResult.itemNotFound =>
                              'This product is no longer in your cart.',
                            CartOperationResult.unchanged =>
                              'The cart quantity was not changed.',
                            CartOperationResult.success => '',
                          };
                          messenger
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                          return;
                        }

                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: _CartAddedNotification(
                                productTitle: product.title,
                                onViewCart: () {
                                  messenger.hideCurrentSnackBar();
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const CartScreen(),
                                    ),
                                  );
                                },
                              ),
                              backgroundColor: const Color(0xFF173D32),
                              behavior: SnackBarBehavior.floating,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                      },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(
                  product.stock <= 0 ? 'Out of Stock' : 'Add to Cart',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartAddedNotification extends StatelessWidget {
  const _CartAddedNotification({
    required this.productTitle,
    required this.onViewCart,
  });

  final String productTitle;
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    const lightGreen = Color(0xFFC9F2D3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF173D32),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF173D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Added to Cart!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Product added successfully',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: lightGreen, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onViewCart,
            style: TextButton.styleFrom(
              foregroundColor: lightGreen,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 18),
                SizedBox(height: 2),
                Text(
                  'VIEW CART',
                  maxLines: 1,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({super.key, required this.imageUrl, required this.fit});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Colors.black38,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProductInformation extends StatelessWidget {
  const _ProductInformation({
    required this.warranty,
    required this.shipping,
    required this.returns,
  });

  final String? warranty;
  final String? shipping;
  final String? returns;

  @override
  Widget build(BuildContext context) {
    final entries = [
      if (_hasText(warranty))
        (Icons.verified_user_outlined, 'Warranty', warranty!),
      if (_hasText(shipping))
        (Icons.local_shipping_outlined, 'Shipping', shipping!),
      if (_hasText(returns))
        (Icons.assignment_return_outlined, 'Returns', returns!),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    entries[index].$1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[index].$2,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entries[index].$3,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class _CustomerReviews extends StatelessWidget {
  const _CustomerReviews({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Reviews',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.star_rounded, color: colors.tertiary, size: 25),
            const SizedBox(width: 5),
            Text(
              product.rating.toStringAsFixed(1),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              'Average rating · ${product.reviews.length} reviews',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (product.reviews.isEmpty)
          const _SectionMessage(message: 'No customer reviews yet.')
        else
          ...product.reviews.map((review) => _ReviewCard(review: review)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final reviewer = review.reviewerName.trim().isEmpty
        ? 'Customer'
        : review.reviewerName;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reviewer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  review.date == null
                      ? 'Date unavailable'
                      : _formatReviewDate(review.date!),
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating
                      ? Icons.star_rounded
                      : Icons.star_border,
                  size: 17,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.comment,
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatReviewDate(DateTime date) {
  final localDate = date.toLocal();
  final month = localDate.month.toString().padLeft(2, '0');
  final day = localDate.day.toString().padLeft(2, '0');
  return '$month/$day/${localDate.year}';
}

class _RelatedProductsSection extends StatelessWidget {
  const _RelatedProductsSection({
    required this.products,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You May Also Like',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (errorMessage != null)
          _SectionMessage(message: errorMessage!, onRetry: onRetry)
        else if (products.isEmpty)
          const _SectionMessage(message: 'No related products found.')
        else
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return _RelatedProductCard(
                  product: product,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProductDetailsScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 156,
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F3F5),
                  padding: const EdgeInsets.all(8),
                  child: _ProductImage(
                    imageUrl: product.thumbnail,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: colors.tertiary,
                        ),
                        Text(product.rating.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.black54)),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
