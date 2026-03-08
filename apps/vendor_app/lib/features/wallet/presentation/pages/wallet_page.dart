import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/wallet_model.dart';
import '../providers/wallet_provider.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Wallet')),
      body: walletState.isLoading
          ? const LoadingWidget(message: 'Loading wallet...')
          : walletState.error != null && walletState.wallet == null
              ? AppErrorWidget(
                  message: walletState.error!,
                  onRetry: () =>
                      ref.read(walletProvider.notifier).loadWallet(),
                )
              : walletState.wallet == null
                  ? const LoadingWidget(message: 'Loading...')
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(walletProvider.notifier)
                            .loadWallet();
                        await ref
                            .read(walletProvider.notifier)
                            .loadTransactions();
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        children: [
                          // Balance Card
                          _buildBalanceCard(
                              context, ref, walletState.wallet!),
                          const SizedBox(height: AppTheme.spacingBase),

                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  label: 'Total Earned',
                                  value: walletState
                                      .wallet!.totalEarnings.toPrice,
                                  icon: Icons.trending_up_rounded,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMd),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  label: 'Total Payouts',
                                  value: walletState
                                      .wallet!.totalPayouts.toPrice,
                                  icon: Icons.account_balance_rounded,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingXl),

                          // Transaction history header
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaction History',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          if (walletState.isTransactionsLoading)
                            const LoadingWidget(
                                message: 'Loading transactions...')
                          else if (walletState.transactions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(AppTheme.spacing2xl),
                              child: EmptyStateWidget(
                                message: 'No transactions yet',
                                icon: Icons.receipt_long_outlined,
                              ),
                            )
                          else
                            ...walletState.transactions.map((t) =>
                                _buildTransactionTile(context, t)),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, WidgetRef ref, WalletModel wallet) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                'Available Balance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            wallet.balance.toPrice,
            style: theme.textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 36,
            ),
          ),
          if (wallet.pendingPayout > 0) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: AppTheme.spacingXs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                'Pending payout: ${wallet.pendingPayout.toPrice}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: wallet.balance > 0
                  ? () => _showPayoutDialog(context, ref, wallet)
                  : null,
              icon: const Icon(Icons.payments_outlined, size: 18),
              label: const Text('Request Payout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: wallet.balance > 0
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
      BuildContext context, WalletTransactionModel transaction) {
    final theme = Theme.of(context);
    final isCredit = transaction.isCredit;
    final color = isCredit ? AppTheme.successColor : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Circle icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),

          // Description & date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  transaction.createdAt.toFormattedDateTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isCredit ? '+' : '-'}${transaction.amount.toPrice}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(
      BuildContext context, WidgetRef ref, WalletModel wallet) {
    final amountController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.payments_outlined,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            const Text('Request Payout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Available: ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    wallet.balance.toPrice,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\u20B9 ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [500.0, 1000.0, 2000.0]
                  .map((amt) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2),
                          child: OutlinedButton(
                            onPressed: () => amountController.text =
                                amt.toStringAsFixed(0),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacingXs),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              '\u20B9${amt.toStringAsFixed(0)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'Processed within 2-3 business days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text.trim());
              if (amount == null || amount <= 0) {
                context.showSnackBar('Enter a valid amount',
                    isError: true);
                return;
              }
              if (amount > wallet.balance) {
                context.showSnackBar('Exceeds available balance',
                    isError: true);
                return;
              }
              Navigator.pop(ctx);
              final success = await ref
                  .read(walletProvider.notifier)
                  .requestPayout(amount);
              if (success && context.mounted) {
                context.showSuccessSnackBar('Payout request submitted');
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
