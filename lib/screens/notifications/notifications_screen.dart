import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            floating: false,
            actions: [
              if (notifications.isNotEmpty) ...[
                IconButton(
                  tooltip: 'Mark all as read',
                  icon: const Icon(Icons.mark_chat_read_outlined),
                  onPressed: () => provider.markAllAsRead(),
                ),
                IconButton(
                  tooltip: 'Clear all',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => provider.clearNotifications(),
                ),
              ],
            ],
            flexibleSpace: const FlexibleSpaceBar(
              title: Text('Notifications'),
              titlePadding: EdgeInsetsDirectional.only(start: 16, bottom: 12),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: notifications.isNotEmpty,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 64,
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No new notifications',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          elevation: 0,
                          color: AppTheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppTheme.border),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) => Divider(color: AppTheme.border),
                            itemBuilder: (context, index) {
                              final note = notifications[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: note.isRead
                                      ? AppTheme.textSecondary.withValues(alpha: 0.1)
                                      : AppTheme.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    note.isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: note.isRead ? AppTheme.textSecondary : AppTheme.primary,
                                  ),
                                ),
                                title: Text(
                                  note.title,
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: note.isRead ? FontWeight.w500 : FontWeight.w700,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      note.body,
                                      style: TextStyle(
                                        color: note.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(note.timestamp),
                                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                                    ),
                                  ],
                                ),
                                onTap: () => provider.markAsRead(note.id),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
