import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../product/data/models/product_model.dart';
import '../../../service/data/models/service_model.dart';

// ── Search State ────────────────────────────────────────────────────────

class SearchState {
  final bool isLoading;
  final String query;
  final List<ProductModel> products;
  final List<ServiceModel> services;
  final List<String> suggestions;
  final List<String> recentSearches;
  final String? error;

  const SearchState({
    this.isLoading = false,
    this.query = '',
    this.products = const [],
    this.services = const [],
    this.suggestions = const [],
    this.recentSearches = const [],
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    String? query,
    List<ProductModel>? products,
    List<ServiceModel>? services,
    List<String>? suggestions,
    List<String>? recentSearches,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      products: products ?? this.products,
      services: services ?? this.services,
      suggestions: suggestions ?? this.suggestions,
      recentSearches: recentSearches ?? this.recentSearches,
      error: error,
    );
  }
}

// ── Search Notifier ─────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounce;

  SearchNotifier(this._ref) : super(const SearchState());

  void onQueryChanged(String query) {
    state = state.copyWith(query: query);

    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(
        products: [],
        services: [],
        suggestions: [],
      );
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final updated = [
      query.trim(),
      ...state.recentSearches
          .where((s) => s.toLowerCase() != query.trim().toLowerCase()),
    ].take(10).toList();
    state = state.copyWith(recentSearches: updated);
  }

  void removeRecentSearch(String query) {
    final updated =
        state.recentSearches.where((s) => s != query).toList();
    state = state.copyWith(recentSearches: updated);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
  }

  Future<void> _performSearch(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get(
        ApiEndpoints.search,
        queryParameters: {'q': query, 'perPage': 20},
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      final products = (data['products'] as List<dynamic>? ?? [])
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final services = (data['services'] as List<dynamic>? ?? [])
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Add to recent searches on successful search
      addRecentSearch(query);

      state = state.copyWith(
        isLoading: false,
        products: products,
        services: services,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});

// ── Search Page ─────────────────────────────────────────────────────────

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // ── Search Header ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + AppTheme.spacingMd,
              left: AppTheme.spacingBase,
              right: AppTheme.spacingBase,
              bottom: AppTheme.spacingMd,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.card,
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Back button + search field
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius:
                              BorderRadius.circular(AppTheme.spacingXl),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products, services...',
                            hintStyle:
                                theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppTheme.textTertiary,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      ref
                                          .read(searchProvider.notifier)
                                          .onQueryChanged('');
                                      setState(() {});
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppTheme.textTertiary,
                                      size: 18,
                                    ),
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            ref
                                .read(searchProvider.notifier)
                                .onQueryChanged(value);
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // Tab bar (only when there are results)
                if (searchState.query.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        text:
                            'Products (${searchState.products.length})',
                      ),
                      Tab(
                        text:
                            'Services (${searchState.services.length})',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────────────
          Expanded(
            child: searchState.query.isEmpty
                ? _buildEmptyState(context, theme, searchState)
                : searchState.isLoading
                    ? _buildLoadingSkeleton()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Products tab
                          searchState.products.isEmpty
                              ? _buildNoResults(
                                  context, theme, 'No products found')
                              : _buildProductGrid(
                                  context, theme, searchState),

                          // Services tab
                          searchState.services.isEmpty
                              ? _buildNoResults(
                                  context, theme, 'No services found')
                              : _buildServicesList(
                                  context, theme, searchState),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Empty State (recent searches + initial prompt) ────────────────────

  Widget _buildEmptyState(
      BuildContext context, ThemeData theme, SearchState searchState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (searchState.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      ref.read(searchProvider.notifier).clearRecentSearches(),
                  child: Text(
                    'Clear All',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: searchState.recentSearches.map((search) {
                return _RecentSearchChip(
                  label: search,
                  onTap: () {
                    _searchController.text = search;
                    ref
                        .read(searchProvider.notifier)
                        .onQueryChanged(search);
                    setState(() {});
                  },
                  onDelete: () {
                    ref
                        .read(searchProvider.notifier)
                        .removeRecentSearch(search);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing2xl),
          ],

          // Prompt illustration
          Center(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacing4xl),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingBase),
                Text(
                  'Search for products and services',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading Skeleton ──────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: SkeletonGrid(
        crossAxisCount: 2,
        itemCount: 6,
        childAspectRatio: 0.68,
      ),
    );
  }

  // ── No Results ────────────────────────────────────────────────────────

  Widget _buildNoResults(
      BuildContext context, ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 32,
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Try adjusting your search terms',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Product Grid ──────────────────────────────────────────────────────

  Widget _buildProductGrid(
      BuildContext context, ThemeData theme, SearchState searchState) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: AppTheme.spacingMd,
        mainAxisSpacing: AppTheme.spacingMd,
      ),
      itemCount: searchState.products.length,
      itemBuilder: (context, index) {
        final product = searchState.products[index];
        return ProductCard(
          id: product.id,
          name: product.name,
          price: product.price,
          comparePrice: product.comparePrice,
          imageUrl:
              product.images.isNotEmpty ? product.images.first : null,
          rating: product.rating,
          reviewCount: product.reviewCount,
          vendorName: product.vendorName,
        );
      },
    );
  }

  // ── Services List ─────────────────────────────────────────────────────

  Widget _buildServicesList(
      BuildContext context, ThemeData theme, SearchState searchState) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      itemCount: searchState.services.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final service = searchState.services[index];
        return _ServiceSearchTile(service: service);
      },
    );
  }
}

// ── Recent Search Chip ──────────────────────────────────────────────────

class _RecentSearchChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecentSearchChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 14,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Search Tile ─────────────────────────────────────────────────

class _ServiceSearchTile extends StatelessWidget {
  final ServiceModel service;

  const _ServiceSearchTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/services/${service.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Service image
            SizedBox(
              width: 100,
              height: 100,
              child: service.images.isNotEmpty
                  ? Image.network(
                      service.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.surface,
                        child: const Icon(
                          Icons.home_repair_service_outlined,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.surface,
                      child: const Icon(
                        Icons.home_repair_service_outlined,
                        color: AppTheme.textTertiary,
                      ),
                    ),
            ),

            // Service details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    if (service.vendorName != null)
                      Text(
                        service.vendorName!,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      children: [
                        Text(
                          service.price.toPrice,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 10,
                                color: AppTheme.textTertiary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                service.formattedDuration,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (service.rating > 0) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  service.rating.toStringAsFixed(1),
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            ),

            // Chevron
            const Padding(
              padding: EdgeInsets.only(right: AppTheme.spacingMd),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
