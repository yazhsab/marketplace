import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/product_card.dart';
import '../providers/product_provider.dart';

class ProductListPage extends ConsumerStatefulWidget {
  final String? category;

  const ProductListPage({super.key, this.category});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final _scrollController = ScrollController();
  String? _selectedSort;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.category != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(productListProvider.notifier).setCategory(widget.category);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _selectedSort = value);
              ref.read(productListProvider.notifier).setSort(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'newest', child: Text('Newest First')),
              const PopupMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
              const PopupMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
              const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
              const PopupMenuItem(value: 'popular', child: Text('Most Popular')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_selectedSort != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(_getSortLabel(_selectedSort!)),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _selectedSort = null);
                      ref.read(productListProvider.notifier).setSort(null);
                    },
                  ),
                ],
              ),
            ),

          // Product grid
          Expanded(
            child: state.isLoading
                ? const LoadingWidget()
                : state.error != null
                    ? AppErrorWidget(
                        message: state.error!,
                        onRetry: () => ref
                            .read(productListProvider.notifier)
                            .loadProducts(refresh: true),
                      )
                    : state.products.items.isEmpty
                        ? const EmptyStateWidget(
                            message: 'No products found',
                            icon: Icons.shopping_bag_outlined,
                          )
                        : GridView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: state.products.items.length +
                                (state.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.products.items.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final product = state.products.items[index];
                              return ProductCard(
                                id: product.id,
                                name: product.name,
                                price: product.price,
                                comparePrice: product.comparePrice,
                                imageUrl: product.images.isNotEmpty
                                    ? product.images.first
                                    : null,
                                rating: product.rating,
                                reviewCount: product.reviewCount,
                                vendorName: product.vendorName,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'newest':
        return 'Newest First';
      case 'price_asc':
        return 'Price: Low to High';
      case 'price_desc':
        return 'Price: High to Low';
      case 'rating':
        return 'Highest Rated';
      case 'popular':
        return 'Most Popular';
      default:
        return sort;
    }
  }
}
