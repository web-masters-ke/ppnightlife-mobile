import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _posts = [];
  bool _loadingUser = true;
  bool _loadingPosts = true;
  bool _following = false;
  bool _toggling = false;
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _loadUser();
    _loadPosts();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final res = await ApiService().getUser(widget.userId);
      final data = res.data['data'] ?? res.data;
      if (mounted) {
        setState(() {
          _user = data as Map<String, dynamic>?;
          _loadingUser = false;
          // Check if current user follows this user
          final me = ref.read(authProvider).user;
          final followers = (_user?['followers'] as List?) ?? [];
          _following = followers.any((f) {
            final fId = f is Map ? (f['id'] ?? f['_id']) : f;
            return fId == me?.userId;
          });
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadPosts() async {
    try {
      final res = await ApiService().getUserPosts(widget.userId);
      final data = res.data['data'];
      final items = ((data is List ? data : data?['items']) as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _posts = items; _loadingPosts = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (_toggling) return;
    HapticFeedback.lightImpact();
    setState(() => _toggling = true);
    try {
      if (_following) {
        await ApiService().unfollowUser(widget.userId);
      } else {
        await ApiService().followUser(widget.userId);
      }
      setState(() => _following = !_following);
    } catch (_) {}
    if (mounted) setState(() => _toggling = false);
  }

  Future<void> _openChat() async {
    try {
      final res = await ApiService().openChat(widget.userId);
      final roomId = res.data['data']?['roomId'] as String? ?? res.data['data']?['_id'] as String?;
      if (roomId != null && mounted) context.push('/chat/$roomId');
    } catch (_) {}
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = ref.watch(authProvider).user;
    final isOwnProfile = me?.userId == widget.userId;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: _loadingUser
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : _buildProfile(isDark, isOwnProfile),
    );
  }

  Widget _buildProfile(bool isDark, bool isOwnProfile) {
    final user = _user;
    final name = user?['name'] as String? ?? 'User';
    final photo = user?['profilePhoto'] as String?;
    final bio = user?['bio'] as String?;
    final role = user?['role'] as String? ?? '';
    final level = (user?['level'] as num?)?.toInt() ?? 1;
    final xp = (user?['xp'] as num?)?.toInt() ?? 0;
    final followersCount = (user?['followersCount'] as num?)?.toInt() ??
        ((user?['followers'] as List?)?.length ?? 0);
    final followingCount = (user?['followingCount'] as num?)?.toInt() ??
        ((user?['following'] as List?)?.length ?? 0);
    final postsCount = _posts.length;

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          backgroundColor: isDark ? AppColors.bgDark : Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          pinned: true,
          title: Text(
            name,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          leading: IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              size: 22,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMoreHorizontal,
                size: 22,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tc,
            indicatorColor: AppColors.purple,
            dividerColor: Colors.transparent,
            labelColor: AppColors.purple,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            tabs: const [Tab(text: 'Posts'), Tab(text: 'About')],
          ),
        ),

        // Profile header
        SliverToBoxAdapter(
          child: _ProfileHeader(
            name: name,
            photo: photo,
            bio: bio,
            role: role,
            level: level,
            xp: xp,
            followersCount: followersCount,
            followingCount: followingCount,
            postsCount: postsCount,
            isOwnProfile: isOwnProfile,
            following: _following,
            toggling: _toggling,
            isDark: isDark,
            onFollow: _toggleFollow,
            onMessage: _openChat,
          ),
        ),
      ],
      body: TabBarView(
        controller: _tc,
        children: [
          _PostsTab(posts: _posts, loading: _loadingPosts, isDark: isDark),
          _AboutTab(user: user, isDark: isDark),
        ],
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? photo, bio, role;
  final int level, xp, followersCount, followingCount, postsCount;
  final bool isOwnProfile, following, toggling, isDark;
  final VoidCallback onFollow, onMessage;

  const _ProfileHeader({
    required this.name,
    this.photo,
    this.bio,
    this.role,
    required this.level,
    required this.xp,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
    required this.isOwnProfile,
    required this.following,
    required this.toggling,
    required this.isDark,
    required this.onFollow,
    required this.onMessage,
  });

  String get _roleLabel {
    switch (role) {
      case 'dj': return 'DJ';
      case 'merchant': return 'Venue';
      case 'advertiser': return 'Advertiser';
      default: return 'Party Goer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpForNext = (level * 500);
    final progress = (xp % xpForNext) / xpForNext;

    return Container(
      color: isDark ? AppColors.bgDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + stats row
          Row(
            children: [
              // Avatar
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                child: ClipOval(
                  child: photo != null
                      ? CachedNetworkImage(imageUrl: photo!, fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white, size: 36))
                      : const Icon(Icons.person_rounded, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(width: 20),

              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(label: 'Posts', value: '$postsCount'),
                    _Stat(label: 'Followers', value: _fmtCount(followersCount)),
                    _Stat(label: 'Following', value: _fmtCount(followingCount)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Name + role
          Text(name, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          )),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(_roleLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                child: Text('Lv.$level', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                )),
              ),
            ],
          ),

          if (bio != null && bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(bio!, style: TextStyle(
              fontSize: 13, height: 1.4,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            )),
          ],

          // XP bar
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$xp XP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$xpForNext XP', style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            ],
          ),

          if (!isOwnProfile) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onFollow,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: following ? null : AppColors.primaryGradient,
                        color: following ? (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight) : null,
                        borderRadius: BorderRadius.circular(10),
                        border: following ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight) : null,
                      ),
                      child: Center(
                        child: toggling
                            ? const SizedBox(width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                following ? 'Following' : 'Follow',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: following
                                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                      : Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onMessage,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(icon: HugeIcons.strokeRoundedMessage01, size: 16,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        const SizedBox(width: 6),
                        Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        )),
        Text(label, style: TextStyle(
          fontSize: 11,
          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        )),
      ],
    );
  }
}

// ── Posts Tab ─────────────────────────────────────────────────────────────────
class _PostsTab extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  final bool loading, isDark;
  const _PostsTab({required this.posts, required this.loading, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 40,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            const SizedBox(height: 12),
            Text('No posts yet', style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            )),
          ],
        ),
      );
    }

    // Photo grid for image posts, list for text posts
    final imagePosts = posts.where((p) {
      final media = p['media'] as List? ?? [];
      return media.isNotEmpty;
    }).toList();
    final textPosts = posts.where((p) {
      final media = p['media'] as List? ?? [];
      return media.isEmpty;
    }).toList();

    return CustomScrollView(
      slivers: [
        if (imagePosts.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(1),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 1.5, mainAxisSpacing: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final p = imagePosts[i];
                  final media = p['media'] as List? ?? [];
                  final url = media.isNotEmpty
                      ? (media.first is String ? media.first as String : (media.first as Map)['url'] as String? ?? '')
                      : '';
                  final postId = p['postId'] as String? ?? p['_id'] as String? ?? '';
                  return GestureDetector(
                    onTap: () { if (postId.isNotEmpty) context.push('/post/$postId'); },
                    child: url.isNotEmpty
                        ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                              child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38),
                            ))
                        : Container(color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                  );
                },
                childCount: imagePosts.length,
              ),
            ),
          ),
        if (textPosts.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final p = textPosts[i];
                final postId = p['postId'] as String? ?? p['_id'] as String? ?? '';
                final content = p['content'] as String? ?? '';
                final createdAt = p['createdAt'] as String?;
                return GestureDetector(
                  onTap: () { if (postId.isNotEmpty) context.push('/post/$postId'); },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, height: 1.4,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        const SizedBox(height: 4),
                        Text(_fmtTime(createdAt), style: TextStyle(fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      ],
                    ),
                  ),
                );
              },
              childCount: textPosts.length,
            ),
          ),
      ],
    );
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}

// ── About Tab ─────────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool isDark;
  const _AboutTab({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final email = user?['email'] as String?;
    final phone = user?['phone'] as String?;
    final location = user?['location'] as String?;
    final joinedAt = user?['createdAt'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (location != null && location.isNotEmpty)
          _InfoRow(icon: HugeIcons.strokeRoundedLocation01, label: location, isDark: isDark),
        if (email != null && email.isNotEmpty)
          _InfoRow(icon: HugeIcons.strokeRoundedMail01, label: email, isDark: isDark),
        if (phone != null && phone.isNotEmpty)
          _InfoRow(icon: HugeIcons.strokeRoundedSmartPhone01, label: phone, isDark: isDark),
        if (joinedAt != null)
          _InfoRow(icon: HugeIcons.strokeRoundedCalendar01, label: 'Joined ${_fmtJoined(joinedAt)}', isDark: isDark),
        if (location == null && email == null && phone == null && joinedAt == null)
          Center(child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Text('No details available', style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            )),
          )),
      ],
    );
  }

  static String _fmtJoined(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[d.month - 1]} ${d.year}';
    } catch (_) { return ''; }
  }
}

class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final bool isDark;
  const _InfoRow({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 18,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ))),
        ],
      ),
    );
  }
}
