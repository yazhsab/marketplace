import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/review_model.dart';
import '../providers/review_provider.dart';

class ReviewListPage extends ConsumerWidget {
  const ReviewListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(reviewProvider.notifier).loadReviews(),
          ),
        ],
      ),
      body: reviewState.isLoading
          ? const LoadingWidget(message: 'Loading reviews...')
          : reviewState.error != null
              ? AppErrorWidget(
                  message: reviewState.error!,
                  onRetry: () =>
                      ref.read(reviewProvider.notifier).loadReviews(),
                )
              : reviewState.reviews.isEmpty
                  ? const EmptyStateWidget(
                      message: 'No reviews yet',
                      icon: Icons.star_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(reviewProvider.notifier).loadReviews(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingBase),
                        itemCount: reviewState.reviews.length,
                        itemBuilder: (context, index) =>
                            _buildReviewCard(context, ref,
                                reviewState.reviews[index]),
                      ),
                    ),
    );
  }

  Widget _buildReviewCard(
      BuildContext context, WidgetRef ref, ReviewModel review) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Time
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    image: review.customerAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(review.customerAvatar!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: review.customerAvatar == null
                      ? Center(
                          child: Text(
                            review.customerName.isNotEmpty
                                ? review.customerName[0].toUpperCase()
                                : '?',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.createdAt.toTimeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.warningColor, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        review.rating.toString(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Stars row
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: i < review.rating
                      ? AppTheme.warningColor
                      : AppTheme.border,
                  size: 18,
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Item name
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                review.itemName,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Comment
            if (review.comment != null &&
                review.comment!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                review.comment!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],

            // Reply section
            if (review.hasReply) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 14, color: AppTheme.primary),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          'Your reply',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      review.reply!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: AppTheme.spacingSm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      _showReplySheet(context, ref, review),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Reply'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingXs,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplySheet(
      BuildContext context, WidgetRef ref, ReviewModel review) {
    final replyController = TextEditingController();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppTheme.spacingBase,
          right: AppTheme.spacingBase,
          top: AppTheme.spacingBase,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppTheme.spacingBase,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              'Reply to ${review.customerName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            TextField(
              controller: replyController,
              decoration: InputDecoration(
                hintText: 'Write your reply...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            ElevatedButton.icon(
              onPressed: () async {
                final reply = replyController.text.trim();
                if (reply.isEmpty) return;
                Navigator.pop(ctx);
                final success = await ref
                    .read(reviewProvider.notifier)
                    .replyToReview(review.id, reply);
                if (success && context.mounted) {
                  context.showSuccessSnackBar('Reply sent');
                }
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Reply'),
            ),
          ],
        ),
      ),
    );
  }
}
