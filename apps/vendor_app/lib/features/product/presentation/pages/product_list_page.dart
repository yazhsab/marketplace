import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/cached_image.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/product_model.dart';
import '../providers/product_provider.dart';

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Products', style: theme.textTheme.titleLarge),
        backgroundColor: AppTheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(productProvider.notifier).loadProducts(),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/products/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white),
        ),
      ),
      body: productState.isLoading
          ? const LoadingWidget(message: 'Loading products...')
          : productState.error != null
              ? AppErrorWidget(
                  message: productState.error!,
                  onRetry: () =>
                      ref.read(productProvider.notifier).loadProducts(),
                )
              : productState.products.isEmpty
                  ? EmptyStateWidget(
                      message: 'No products yet.\nAdd your first product!',
                      icon: Icons.inventory_2_outlined,
                      actionLabel: 'Add Product',
                      onAction: () => context.push('/products/add'),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(productProvider.notifier).loadProducts(),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppTheme.spacingMd,
                          crossAxisSpacing: AppTheme.spacingMd,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: productState.products.length,
                        itemBuilder: (context, index) => _buildProductCard(
                            context, ref, productState.products[index]),
                      ),
                    ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, WidgetRef ref, ProductModel product) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/products/${product.id}/edit'),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusLg),
                      ),
                      child: CachedImage(
                        imageUrl: product.images.isNotEmpty
                            ? product.images.first
                            : null,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                    // Stock badge
                    Positioned(
                      top: AppTheme.spacingSm,
                      left: AppTheme.spacingSm,
                      child: _buildStockBadge(product),
                    ),
                    // More menu
                    Positioned(
                      top: AppTheme.spacingXs,
                      right: AppTheme.spacingXs,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              context
                                  .push('/products/${product.id}/edit');
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, ref, product);
                            }
                          },
                          icon: const Icon(Icons.more_vert_rounded,
                              color: Colors.white, size: 16),
                          padding: EdgeInsets.zero,
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style: TextStyle(
                                      color: AppTheme.error)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            product.price.toPrice,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                          if (product.hasDiscount) ...[
                            const SizedBox(width: AppTheme.spacingSm),
                            Flexible(
                              child: Text(
                                product.comparePrice!.toPrice,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  decoration:
                                      TextDecoration.lineThrough,
                                  color: AppTheme.textTertiary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(ProductModel product) {
    String label;
    Color badgeColor;

    if (product.isOutOfStock) {
      label = 'Out of Stock';
      badgeColor = AppTheme.error;
    } else if (product.isLowStock) {
      label = 'Low: ${product.stock}';
      badgeColor = AppTheme.warningColor;
    } else {
      label = 'In Stock';
      badgeColor = AppTheme.successColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
            color: badgeColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.id);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
