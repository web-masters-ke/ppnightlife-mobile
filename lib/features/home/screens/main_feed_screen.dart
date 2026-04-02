import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../feed/widgets/story_row.dart';
import '../../feed/widgets/feed_post_card.dart';

// Status background options
const _statusBgs = [
  LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFDB2777)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF9500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFF10B981), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF59E0B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFF1E1E2E), Color(0xFF3730A3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF065F46)], begin: Alignment.topLeft, end: Alignment.bottomRight),
];

const _statusFontStyles = [
  TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w900, fontSize: 22),
  TextStyle(fontWeight: FontWeight.w400, fontSize: 20, fontStyle: FontStyle.italic),
  TextStyle(fontWeight: FontWeight.w300, fontSize: 18, letterSpacing: 2),
  TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
];

class MainFeedScreen extends ConsumerStatefulWidget {
  const MainFeedScreen({super.key});

  @override
  ConsumerState<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends ConsumerState<MainFeedScreen> {
  final _scrollController = ScrollController();
  String _selectedFilter = 'For You';
  final _filters = ['For You', 'Check-ins', 'DJ Updates', 'Photos', 'Videos', 'Trending'];

  List<_MockPost> _posts = [];
  List<_MockVenue> _liveVenuesList = [];
  List<_MockTipper> _topTippersList = [];
  bool _loadingFeed = false;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Defer until after first build so auth state is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootLoad());
  }

  /// Called once after the first frame — auth may or may not be ready yet.
  void _bootLoad() {
    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated) {
      _initialLoadDone = true;
      _loadFeed();
      _loadLiveVenues();
      _loadTopTippers();
    }
    // If still loading auth, ref.listen below will fire when it settles.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore && _hasMore && !_loadingFeed) {
      _loadMore();
    }
  }

  Future<void> _loadFeed() async {
    setState(() { _loadingFeed = true; _page = 1; _hasMore = true; });
    try {
      final res = await ApiService().getFeed(page: 1, limit: 20);
      final data = res.data['data'];
      final items = ((data?['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      final total = (data?['total'] as num?)?.toInt() ?? items.length;
      setState(() {
        _posts = items.map(_mapPost).toList();
        _hasMore = _posts.length < total;
        _loadingFeed = false;
      });
    } catch (_) {
      setState(() { _loadingFeed = false; _hasMore = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final res = await ApiService().getFeed(page: nextPage, limit: 20);
      final data = res.data['data'];
      final items = ((data?['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      final total = (data?['total'] as num?)?.toInt() ?? (_posts.length + items.length);
      setState(() {
        _page = nextPage;
        _posts.addAll(items.map(_mapPost));
        _hasMore = _posts.length < total;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  _MockPost _mapPost(Map<String, dynamic> p) {
    final rawMedia = p['media'] as List? ?? p['mediaUrls'] as List? ?? [];
    // media items can be strings or objects with a 'url' field
    final urls = rawMedia.map((item) {
      if (item is String) return item;
      if (item is Map) return item['url'] as String? ?? '';
      return '';
    }).where((s) => s.isNotEmpty).toList();
    return _MockPost(
      postId: p['postId'] as String? ?? '',
      userId: p['author']?['id'] as String? ?? p['author']?['_id'] as String? ?? '',
      username: p['author']?['name'] as String? ?? 'User',
      userAvatar: p['author']?['profilePhoto'] as String? ?? '',
      timeAgo: _fmtTime(p['createdAt'] as String?),
      venue: p['venue']?['name'] as String? ?? '',
      content: p['content'] as String? ?? '',
      likes: (p['reactionCount'] as num?)?.toInt() ?? 0,
      comments: (p['commentCount'] as num?)?.toInt() ?? 0,
      isImage: urls.isNotEmpty && !_isVideoPost(p, urls),
      isVideo: _isVideoPost(p, urls),
      badge: _badgeFor(p['type'] as String?),
      isDJ: p['author']?['role'] == 'dj',
      level: (p['author']?['level'] as num?)?.toInt(),
      mediaUrls: urls,
    );
  }

  static bool _isVideoPost(Map<String, dynamic> p, List<String> urls) {
    if (p['type'] == 'video') return true;
    if (urls.isNotEmpty) {
      final url = urls.first.toLowerCase();
      if (url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm') ||
          url.contains('/video/') || url.contains('video')) return true;
    }
    return false;
  }

  Future<void> _loadLiveVenues() async {
    try {
      final res = await ApiService().getVenues(limit: 10);
      final items = ((res.data['data']?['items'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (items.isNotEmpty) {
        setState(() {
          _liveVenuesList = items.map((v) => _MockVenue(
            name: v['name'] as String? ?? 'Venue',
            emoji: '🏛️',
            count: (v['currentCheckins'] as num?)?.toInt() ?? 0,
          )).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadTopTippers() async {
    try {
      final res = await ApiService().getTopTippers(limit: 3);
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (items.isNotEmpty) {
        setState(() {
          _topTippersList = items.map((t) => _MockTipper(
            name: t['name'] as String? ?? 'Tipper',
            amount: (t['totalTips'] as num?)?.toInt() ?? 0,
          )).toList();
        });
      }
    } catch (_) {}
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  static String _badgeFor(String? type) {
    switch (type) {
      case 'checkin': return '📍';
      case 'dj_update': return '🎵';
      case 'photo': return '📸';
      default: return '🎉';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_MockPost> get _filtered {
    final posts = _posts;
    if (_selectedFilter == 'For You') return posts;
    if (_selectedFilter == 'Check-ins') return posts.where((p) => p.badge == '📍').toList();
    if (_selectedFilter == 'DJ Updates') return posts.where((p) => p.isDJ).toList();
    if (_selectedFilter == 'Photos') return posts.where((p) => p.isImage).toList();
    if (_selectedFilter == 'Videos') return posts.where((p) => p.isVideo).toList();
    if (_selectedFilter == 'Trending') return posts.where((p) => p.likes > 100).toList();
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = ref.watch(authProvider).user;

    // When auth finishes loading and user is authenticated, load feed if not done yet
    ref.listen(authProvider, (prev, next) {
      if (!_initialLoadDone && next.status == AuthStatus.authenticated) {
        _initialLoadDone = true;
        _loadFeed();
        _loadLiveVenues();
        _loadTopTippers();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgCardLight,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgCardLight,
            surfaceTintColor: Colors.transparent,
            shadowColor: isDark ? Colors.transparent : Colors.black.withOpacity(0.06),
            elevation: 0,
            scrolledUnderElevation: isDark ? 0 : 1,
            forceElevated: !isDark,
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 32, height: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: GradientText(
                    'PartyPeople',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // XP indicator
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '${me?.xpPoints ?? 0} XP',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.purple),
                    ),
                  ],
                ),
              ),
              // Live indicator
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  size: 22,
                ),
                onPressed: () => context.push('/notifications'),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.purple,
          backgroundColor: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          onRefresh: () async {
            _page = 1; _hasMore = true;
            await Future.wait([_loadFeed(), _loadLiveVenues(), _loadTopTippers()]);
          },
          child: CustomScrollView(
            slivers: [
              // Stories / Status row
              const SliverToBoxAdapter(child: StoryRow()),

              // Filter chips
              SliverToBoxAdapter(
                child: Container(
                  color: isDark ? AppColors.bgDark : Colors.white,
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                    children: _filters.map((f) {
                      final sel = f == _selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.primaryGradient : null,
                            color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),


              // Feed posts with leaderboard injected after 5th post
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final posts = _filtered;
                    if (posts.isEmpty) {
                      return _EmptyFilter(isDark: isDark, filter: _selectedFilter);
                    }
                    // Inject leaderboard after 5th post
                    if (index == 5) {
                      if (_topTippersList.isNotEmpty) return _TippersLeaderboard(isDark: isDark, tippers: _topTippersList);
                      return const SizedBox.shrink();
                    }
                    final postIndex = index > 5 ? index - 1 : index;
                    return FeedPostCard(
                      post: posts[postIndex % posts.length],
                      isDark: isDark,
                    );
                  },
                  childCount: _filtered.isEmpty ? 1 : _filtered.length + 2,
                ),
              ),

              // Load more indicator
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: AppColors.purple, strokeWidth: 2)),
                  ),
                ),
              if (!_hasMore && _posts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text("You're all caught up 🎉",
                          style: TextStyle(fontSize: 13, color: AppColors.textMutedDark)),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── LIVE VENUES ROW ─────────────────────────────────────────────────────────
class _LiveVenuesRow extends StatelessWidget {
  final bool isDark;
  final List<_MockVenue> venues;
  const _LiveVenuesRow({required this.isDark, required this.venues});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.bgDark : Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Live Venues Nearby',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: venues.map((v) => _LiveVenueChip(venue: v, isDark: isDark)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveVenueChip extends StatelessWidget {
  final _MockVenue venue;
  final bool isDark;
  const _LiveVenueChip({required this.venue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(venue.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(venue.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              Row(
                children: [
                  Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 3),
                  Text('${venue.count} inside',
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TIPPERS LEADERBOARD ─────────────────────────────────────────────────────
class _TippersLeaderboard extends StatelessWidget {
  final bool isDark;
  final List<_MockTipper> tippers;
  const _TippersLeaderboard({required this.isDark, required this.tippers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Top Tippers Tonight',
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const Spacer(),
              Text('See all',
                  style: TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          ...tippers.asMap().entries.map((e) {
            final medals = ['🥇', '🥈', '🥉'];
            final t = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(e.key < 3 ? medals[e.key] : '${e.key + 1}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 16, color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  ),
                  Text('KES ${t.amount}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── STATUS CREATOR SHEET ────────────────────────────────────────────────────
class _StatusCreatorSheet extends StatefulWidget {
  final bool isDark;
  const _StatusCreatorSheet({required this.isDark});

  @override
  State<_StatusCreatorSheet> createState() => _StatusCreatorSheetState();
}

class _StatusCreatorSheetState extends State<_StatusCreatorSheet> {
  final _ctrl = TextEditingController();
  int _bgIndex = 0;
  int _fontIndex = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bot = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(0, 0, 0, bot + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgElevatedDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Create Status',
                    style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('24h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.orange)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Preview
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: _statusBgs[_bgIndex],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _ctrl,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: _statusFontStyles[_fontIndex].copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Share the vibe...',
                    hintStyle: _statusFontStyles[_fontIndex].copyWith(color: Colors.white54, fontSize: 18),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Background picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Background', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusBgs.asMap().entries.map((e) => GestureDetector(
                        onTap: () => setState(() => _bgIndex = e.key),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            gradient: e.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: e.key == _bgIndex ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: e.key == _bgIndex
                                ? [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)]
                                : null,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Font style picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Font', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(width: 10),
                ...['Bold', 'Italic', 'Light', 'Regular'].asMap().entries.map((e) => GestureDetector(
                  onTap: () => setState(() => _fontIndex = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: e.key == _fontIndex ? AppColors.primaryGradient : null,
                      color: e.key == _fontIndex ? null : (isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: e.key == _fontIndex ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Text(e.value,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: e.key == _fontIndex ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Status posted! Disappears in 24h ✨'),
                  backgroundColor: AppColors.purple,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: const Center(
                  child: Text('Post Status', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFilter extends StatelessWidget {
  final bool isDark;
  final String filter;
  const _EmptyFilter({required this.isDark, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No $filter posts yet',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
class _MockPost {
  final String postId, userId, username, userAvatar, timeAgo, venue, content, badge;
  final int likes, comments;
  final int? level;
  final bool isImage, isVideo, isDJ;
  final List<String> mediaUrls;

  _MockPost({
    this.postId = '',
    this.userId = '',
    required this.username,
    required this.userAvatar,
    required this.timeAgo,
    required this.venue,
    required this.content,
    required this.likes,
    required this.comments,
    required this.isImage,
    required this.badge,
    this.isVideo = false,
    this.isDJ = false,
    this.level,
    this.mediaUrls = const [],
  });
}

class _MockVenue {
  final String name, emoji;
  final int count;
  const _MockVenue({required this.name, required this.emoji, required this.count});
}

class _MockTipper {
  final String name;
  final int amount;
  const _MockTipper({required this.name, required this.amount});
}

