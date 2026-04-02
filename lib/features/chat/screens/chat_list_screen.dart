import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

final _chatRoomsProvider = FutureProvider.autoDispose((ref) async {
  final res = await ApiService().getChatRooms();
  final body = res.data;
  // Handle all possible response shapes from the API
  if (body is Map) {
    final data = body['data'];
    if (data is List) return data;
    if (data is Map) {
      return (data['items'] as List?) ??
             (data['rooms'] as List?) ??
             (data['chats'] as List?) ??
             [];
    }
    // top-level list fields
    final top = (body['rooms'] as List?) ??
                (body['items'] as List?) ??
                (body['chats'] as List?);
    if (top != null) return top;
  }
  if (body is List) return body;
  return <dynamic>[];
});

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomsAsync = ref.watch(_chatRoomsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(fontSize: 15, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(fontSize: 15, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(
                'Messages',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w700, fontSize: 18,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: _searching ? HugeIcons.strokeRoundedCancel01 : HugeIcons.strokeRoundedSearch01,
              size: 22,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) { _searchCtrl.clear(); _query = ''; }
            }),
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedEdit01, size: 22,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            onPressed: () => _showNewChatSheet(context, isDark),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () async => ref.invalidate(_chatRoomsProvider),
        child: roomsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('💬', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Failed to load chats',
                    style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(height: 12),
                TextButton(onPressed: () => ref.invalidate(_chatRoomsProvider),
                    child: const Text('Retry', style: TextStyle(color: AppColors.purple))),
              ],
            ),
          ),
          data: (rooms) {
            final filtered = _query.isEmpty
                ? rooms
                : rooms.where((r) {
                    final room = r as Map<String, dynamic>;
                    final name = (room['otherUser'] as Map?)?.get('name')?.toString().toLowerCase() ?? '';
                    final last = ((room['lastMessage'] as Map?)?['content'] as String? ?? '').toLowerCase();
                    return name.contains(_query.toLowerCase()) || last.contains(_query.toLowerCase());
                  }).toList();

            final online = filtered.where((r) => (r as Map)['isOnline'] == true).toList();

            return Column(
              children: [
                // Online row
                if (online.isNotEmpty && !_searching) ...[
                  Container(
                    height: 90,
                    color: isDark ? AppColors.bgDark : Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      itemCount: online.length,
                      itemBuilder: (ctx, i) {
                        final room = online[i] as Map<String, dynamic>;
                        final other = room['otherUser'] as Map<String, dynamic>;
                        final roomId = room['roomId'] as String;
                        final name = other['name'] as String? ?? 'Unknown';
                        return GestureDetector(
                          onTap: () => context.push('/chat/$roomId'),
                          child: Container(
                            margin: const EdgeInsets.only(right: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                                      child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
                                    ),
                                    Positioned(bottom: 1, right: 1,
                                      child: Container(width: 12, height: 12,
                                        decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle,
                                            border: Border.all(color: isDark ? AppColors.bgDark : Colors.white, width: 2)))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(name.split(' ').first,
                                    style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 0.5, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ],

                // Chat list
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('💬', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text('No conversations found',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final room = filtered[i] as Map<String, dynamic>;
                            return _ChatTile(
                              room: room, isDark: isDark,
                              onTap: () => context.push('/chat/${room['roomId']}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showNewChatSheet(BuildContext context, bool isDark) {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.7,
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevatedDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4,
                    decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('New Conversation',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (q) async {
                    if (q.length < 2) { setS(() => results = []); return; }
                    setS(() => searching = true);
                    try {
                      final res = await ApiService().searchUsers(q: q, limit: 10);
                      setS(() {
                        results = ((res.data['data']['items'] as List?) ?? []).cast<Map<String, dynamic>>();
                        searching = false;
                      });
                    } catch (_) {
                      setS(() => searching = false);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: searching
                      ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                      : results.isEmpty
                          ? Center(child: Text('Search to find people to message',
                              style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)))
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final u = results[i];
                                final name = u['name'] as String? ?? 'Unknown';
                                final role = u['role'] as String? ?? '';
                                return ListTile(
                                  leading: Container(
                                    width: 40, height: 40,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                                    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                                  ),
                                  title: Text(name, style: TextStyle(fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                                  subtitle: Text(role, style: TextStyle(fontSize: 12,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                                  onTap: () async {
                                    try {
                                      final res = await ApiService().openChat(u['userId'] as String);
                                      final roomId = res.data['data']['roomId'] as String;
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        ref.invalidate(_chatRoomsProvider);
                                        context.push('/chat/$roomId');
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text('$e'),
                                          backgroundColor: AppColors.red,
                                        ));
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _MapExt on Map {
  dynamic get(String key) => this[key];
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final bool isDark;
  final VoidCallback onTap;
  const _ChatTile({required this.room, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final other = room['otherUser'] as Map<String, dynamic>;
    final name = other['name'] as String? ?? 'Unknown';
    final isOnline = room['isOnline'] as bool? ?? false;
    final unread = room['unreadCount'] as int? ?? 0;
    final lastMsg = room['lastMessage'] as Map<String, dynamic>?;
    final lastContent = lastMsg?['content'] as String? ?? '';
    final updatedAt = room['updatedAt'] as String? ?? '';
    final timeStr = _fmtTime(updatedAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: unread > 0 ? AppColors.purple.withOpacity(isDark ? 0.05 : 0.03) : Colors.transparent,
          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                  child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                if (isOnline)
                  Positioned(bottom: 1, right: 1,
                    child: Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.bgDark : AppColors.bgLight, width: 2)))),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name,
                          style: TextStyle(fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500, fontSize: 15,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
                      Text(timeStr, style: TextStyle(fontSize: 12,
                          color: unread > 0 ? AppColors.purple : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(child: Text(
                        lastContent.isNotEmpty ? lastContent : 'No messages yet',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13,
                          fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
                          color: unread > 0
                              ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                              : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      )),
                      if (unread > 0)
                        Container(
                          width: 20, height: 20,
                          decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                          child: Center(child: Text('$unread',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
