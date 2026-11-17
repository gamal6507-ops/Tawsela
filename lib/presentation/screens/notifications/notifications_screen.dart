import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toktok/core/theme/app_theme.dart';
import 'package:toktok/domain/models/app_notification.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_cubit.dart';
import 'package:toktok/presentation/blocs/notifications/notifications_state.dart';
import 'package:toktok/presentation/widgets/empty_state.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationsCubit>().clearAll(),
            child: Text('مسح الكل', style: GoogleFonts.cairo(color: AppColors.error, fontSize: 14)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              if (state is NotificationsLoading || state is NotificationsInitial) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              if (state is NotificationsEmpty) {
                return const EmptyState(
                  icon: Icons.notifications_off_outlined,
                  title: 'مفيش إشعارات',
                  subtitle: 'هنا هتظهر إشعاراتك الجديدة',
                );
              }
              if (state is NotificationsLoaded) {
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _buildNotificationTile(notification);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.ride:
        icon = Icons.directions_car_outlined;
        iconColor = AppColors.accent;
        break;
      case NotificationType.offer:
        icon = Icons.local_offer_outlined;
        iconColor = AppColors.success;
        break;
      case NotificationType.rating:
        icon = Icons.star_outline;
        iconColor = AppColors.accent;
        break;
      case NotificationType.wallet:
        icon = Icons.account_balance_wallet_outlined;
        iconColor = AppColors.success;
        break;
    }

    return GestureDetector(
      onTap: () => context.read<NotificationsCubit>().markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? null : AppColors.accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(notification.date),
                    style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
