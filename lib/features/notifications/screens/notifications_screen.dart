import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

final _notifsProvider = FutureProvider.autoDispose((ref) async {
  final res = await ApiService().getNotifications(limit: 50);
  return (res.data['data']['items'] as List?) ?? [];
});

const _kNotifFilters = ['All', 'Unread', 'DJ', 'Social', 'Offers', 'Badges'];

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'All';

  List<Map<String, dynamic>> _applyFilter(List<dynamic> items) {
    final all = items.cast<Map<String, dynamic>>();
    switch (_filter) {
      case 'Unread': return all.where((n) => !(n['read'] as bool? ?? true)).toList();
      case 'DJ': return all.where((n) => (n['type'] as String?) == 'dj').toList();
      case 'Social': return all.where((n) => (n['type'] as String?) == 'social').toList();
      case 'Offers': return all.where((n) => (n['type'] as String?) == 'offer').toList();
      case 'Badges': return all.where((n) => (n['type'] as String?) == 'badge').toList();
      default: return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifsAsync = ref.watch(_notifsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ApiService().markAllNotificationsRead();
                ref.invalidate(_notifsProvider);
              } catch (_) {}
            },
            child: const Text('Mark all read', style: TextStyle(color: AppColors.purple, fontSize: 13)),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              itemCount: _kNotifFilters.length,
              itemBuilder: (context, i) {
                final f = _kNotifFilters[i];
                final sel = f == _filter;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Text(f, style: TextStyle(
                      fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    )),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () async => ref.invalidate(_notifsProvider),
        child: notifsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('Failed to load notifications',
                    style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.invalidate(_notifsProvider),
                  child: const Text('Retry', style: TextStyle(color: AppColors.purple)),
                ),
              ],
            ),
          ),
          data: (items) {
            final filtered = _applyFilter(items);
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🔔', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'All' ? 'No notifications yet' : 'No $_filter notifications',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ],
                ),
              );
            }

            final now = DateTime.now();
            final today = <Map<String, dynamic>>[];
            final earlier = <Map<String, dynamic>>[];

            for (final n in filtered) {
              final ts = n['createdAt'] as String? ?? '';
              try {
                final dt = DateTime.parse(ts).toLocal();
                if (now.difference(dt).inHours < 24) {
                  today.add(n);
                } else {
                  earlier.add(n);
                }
              } catch (_) {
                earlier.add(n);
              }
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (today.isNotEmpty) ...[
                  _NotifHeader(label: 'Today', isDark: isDark),
                  ...today.map((n) => _NotifTile(notif: n, isDark: isDark, onTap: () async {
                    try {
                      await ApiService().markNotificationRead(n['notificationId'] as String);
                      ref.invalidate(_notifsProvider);
                    } catch (_) {}
                  })),
                ],
                if (earlier.isNotEmpty) ...[
                  _NotifHeader(label: 'Earlier', isDark: isDark),
                  ...earlier.map((n) => _NotifTile(notif: n, isDark: isDark, onTap: () async {
                    try {
                      await ApiService().markNotificationRead(n['notificationId'] as String);
                      ref.invalidate(_notifsProvider);
                    } catch (_) {}
                  })),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotifHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _NotifHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, letterSpacing: 0.5),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool isDark;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !(notif['read'] as bool? ?? true);
    final type = notif['type'] as String? ?? 'general';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final ts = notif['createdAt'] as String? ?? '';
    final timeStr = _fmtTime(ts);
    final (emoji, gradient) = _typeStyle(type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.purple.withOpacity(isDark ? 0.06 : 0.04)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
                ),
                if (isUnread)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.bgDark : AppColors.bgLight, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(body, style: TextStyle(fontSize: 13, height: 1.4,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                  const SizedBox(height: 3),
                  Text(timeStr, style: TextStyle(fontSize: 12,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, Gradient) _typeStyle(String type) {
    switch (type) {
      case 'social': return ('👤', AppColors.primaryGradient);
      case 'message': return ('💬', AppColors.primaryGradient);
      case 'dj': return ('🎵', AppColors.warmGradient);
      case 'venue': return ('🏛️', AppColors.cyanGradient);
      case 'checkin': return ('📍', AppColors.cyanGradient);
      default: return ('🔔', AppColors.primaryGradient);
    }
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays} days ago';
    } catch (_) {
      return ts;
    }
  }
}
