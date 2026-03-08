import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/earnings_model.dart';
import '../providers/earnings_provider.dart';

class EarningsPage extends ConsumerStatefulWidget {
  const EarningsPage({super.key});

  @override
  ConsumerState<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends ConsumerState<EarningsPage>
    with SingleTickerProviderStateMixin {
  late TabController _periodTabController;

  @override
  void initState() {
    super.initState();
    _periodTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _periodTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earningsState = ref.watch(earningsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Earnings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: earningsState.isLoading
          ? const LoadingWidget(message: 'Loading earnings...')
          : earningsState.error != null && earningsState.earnings == null
              ? AppErrorWidget(
                  message: earningsState.error!,
                  onRetry: () =>
                      ref.read(earningsProvider.notifier).loadEarnings(),
                )
              : earningsState.earnings == null
                  ? const LoadingWidget()
                  : RefreshIndicator(
                      color: AppTheme.primary,
                      onRefresh: () async {
                        await ref
                            .read(earningsProvider.notifier)
                            .loadEarnings();
                        await ref
                            .read(earningsProvider.notifier)
                            .loadHistory();
                      },
                      child: ListView(
                        padding:
                            const EdgeInsets.all(AppTheme.spacingBase),
                        children: [
                          // -- Balance Card with Gradient --
                          _buildBalanceCard(
                              theme, earningsState.earnings!),
                          const SizedBox(height: AppTheme.spacingLg),

                          // -- Period Tabs --
                          _buildPeriodTabs(
                              theme, earningsState.earnings!),
                          const SizedBox(height: AppTheme.spacingXl),

                          // -- Transaction History --
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction History',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (earningsState.history.isNotEmpty)
                                Text(
                                  '${earningsState.history.length} transactions',
                                  style: theme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          if (earningsState.isHistoryLoading)
                            const LoadingWidget(
                                message: 'Loading history...')
                          else if (earningsState.history.isEmpty)
                            const Padding(
                              padding:
                                  EdgeInsets.all(AppTheme.spacing2xl),
                              child: EmptyStateWidget(
                                message: 'No earnings history yet',
                                icon: Icons.receipt_long_outlined,
                              ),
                            )
                          else
                            ...earningsState.history.map(
                                (h) => _buildHistoryTile(theme, h)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme, EarningsModel earnings) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                'Total Earnings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            earnings.totalEarnings.toPrice,
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${earnings.totalDeliveries} deliveries completed',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTabs(ThemeData theme, EarningsModel earnings) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            margin: const EdgeInsets.all(AppTheme.spacingXs),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TabBar(
              controller: _periodTabController,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'This Week'),
                Tab(text: 'This Month'),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: theme.textTheme.labelLarge,
              unselectedLabelStyle: theme.textTheme.bodySmall,
              padding: const EdgeInsets.all(AppTheme.spacingXs),
            ),
          ),

          // Tab Content
          SizedBox(
            height: 80,
            child: TabBarView(
              controller: _periodTabController,
              children: [
                _buildPeriodContent(
                    theme, earnings.todayEarnings.toPrice, 'Today'),
                _buildPeriodContent(
                    theme, earnings.weekEarnings.toPrice, 'This Week'),
                _buildPeriodContent(theme, earnings.monthEarnings.toPrice,
                    'This Month'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodContent(
      ThemeData theme, String amount, String period) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                period,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                amount,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.trending_up,
                color: AppTheme.primary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, EarningsHistoryItem item) {
    final isCredit = item.isCredit;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCredit
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : AppTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                isCredit
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: isCredit ? AppTheme.successColor : AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: AppTheme.textTertiary),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        item.createdAt.formattedDateTime,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '-'}${item.amount.toPrice}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isCredit ? AppTheme.successColor : AppTheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
