import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

// 6 reaction types matching the web
const _reactions = [
  ('❤️', 'love'),
  ('🔥', 'fire'),
  ('💜', 'vibe'),
  ('🎉', 'party'),
  ('😂', 'lol'),
  ('😮', 'wow'),
];

class FeedPostCard extends StatefulWidget {
  final dynamic post;
  final bool isDark;

  const FeedPostCard({super.key, required this.post, required this.isDark});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> with TickerProviderStateMixin {
  bool _liked = false;
  int _likes = 0;
  String? _myReaction;
  Map<String, int> _reactionCounts = {};
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late AnimationController _reactionPopController;
  late Animation<double> _reactionPopScale;
  bool _showReactionBar = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes as int;
    // Seed some reactions for mock posts
    _reactionCounts = {
      '❤️': (_likes * 0.4).round(),
      '🔥': (_likes * 0.3).round(),
      '💜': (_likes * 0.15).round(),
      '🎉': (_likes * 0.1).round(),
    };
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeInOut));

    _reactionPopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _reactionPopScale = CurvedAnimation(parent: _reactionPopController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _heartController.dispose();
    _reactionPopController.dispose();
    super.dispose();
  }

  String? get _postId {
    try { return widget.post.postId as String?; } catch (_) { return null; }
  }

  void _toggleLike() {
    HapticFeedback.lightImpact();
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    if (_liked) _heartController.forward(from: 0);
    final id = _postId;
    if (id != null && id.isNotEmpty) {
      ApiService().reactPost(id, 'love').catchError((_) {});
    }
  }

  void _onReactionTap(String emoji) {
    HapticFeedback.lightImpact();
    final reactions = const [('❤️', 'love'), ('🔥', 'fire'), ('💜', 'vibe'), ('🎉', 'party'), ('😂', 'lol'), ('😮', 'wow')];
    final reactionType = reactions.firstWhere((r) => r.$1 == emoji, orElse: () => (emoji, 'love')).$2;
    setState(() {
      if (_myReaction == emoji) {
        _reactionCounts[emoji] = (_reactionCounts[emoji] ?? 1) - 1;
        if (_reactionCounts[emoji]! <= 0) _reactionCounts.remove(emoji);
        _myReaction = null;
      } else {
        if (_myReaction != null) {
          _reactionCounts[_myReaction!] = (_reactionCounts[_myReaction!] ?? 1) - 1;
          if (_reactionCounts[_myReaction!]! <= 0) _reactionCounts.remove(_myReaction!);
        }
        _myReaction = emoji;
        _reactionCounts[emoji] = (_reactionCounts[emoji] ?? 0) + 1;
      }
      _showReactionBar = false;
    });
    _reactionPopController.reverse();
    final id = _postId;
    if (id != null && id.isNotEmpty) {
      ApiService().reactPost(id, reactionType).catchError((_) {});
    }
  }

  void _onLongPressLike() {
    HapticFeedback.mediumImpact();
    setState(() => _showReactionBar = !_showReactionBar);
    if (_showReactionBar) {
      _reactionPopController.forward(from: 0);
    } else {
      _reactionPopController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = widget.isDark;
    final isCheckin = post.badge == '📍';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check-in badge header
          if (isCheckin) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.purple.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📍', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Text(
                    'Checked in at ${post.venue}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('+50 XP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: post.isDJ as bool
                            ? AppColors.warmGradient
                            : AppColors.primaryGradient,
                      ),
                      child: Center(
                        child: (post.userAvatar as String).isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  post.userAvatar as String,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : const HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                size: 22,
                                color: Colors.white,
                              ),
                      ),
                    ),
                    if (post.isDJ as bool)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.pink,
                            shape: BoxShape.circle,
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedMusicNote01,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.username as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          if (post.isDJ as bool) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppColors.warmGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DJ',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          // XP level badge
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Text(
                              'Lv.${post.level ?? 5}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!isCheckin) ...[
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedLocation01,
                              size: 11,
                              color: AppColors.purple,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              post.venue as String,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.purple,
                              ),
                            ),
                            Text(
                              ' · ${post.timeAgo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ] else ...[
                            Text(
                              post.timeAgo as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // More
                GestureDetector(
                  onTap: () {
                    final id = _postId;
                    if (id != null && id.isNotEmpty) context.push('/post/$id');
                  },
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreHorizontal,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              post.content as String,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),

          // Media
          if (post.isImage as bool) ...[
            const SizedBox(height: 10),
            _PostMediaGrid(
              urls: (() {
                try {
                  final raw = (post as dynamic).mediaUrls;
                  if (raw is List<String>) return raw;
                  if (raw is List) return raw.whereType<String>().toList();
                  return <String>[];
                } catch (_) { return <String>[]; }
              })(),
              isDark: isDark,
            ),
          ],

          // Reaction summary row
          if (_reactionCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Top 3 reaction emojis
                  ...(() {
                    final sorted = _reactionCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    return sorted.take(3).map((e) => Text(e.key, style: const TextStyle(fontSize: 14)));
                  })(),
                  const SizedBox(width: 5),
                  Text(
                    _formatCount(_reactionCounts.values.fold(0, (a, b) => a + b)),
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ],
              ),
            ),
          ],

          // Reaction picker bar (shown on long press)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _showReactionBar
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: ScaleTransition(
                      scale: _reactionPopScale,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.bgCardDark : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _reactions.map((r) => GestureDetector(
                            onTap: () => _onReactionTap(r.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _myReaction == r.$1 ? AppColors.purple.withOpacity(0.15) : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                r.$1,
                                style: TextStyle(fontSize: _myReaction == r.$1 ? 26 : 22),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Row(
              children: [
                // Like / Reaction
                GestureDetector(
                  onTap: _myReaction != null ? () => _onReactionTap(_myReaction!) : _toggleLike,
                  onLongPress: _onLongPressLike,
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _heartController,
                        builder: (context, child) => Transform.scale(
                          scale: _myReaction != null ? 1.0 : _heartScale.value,
                          child: _myReaction != null
                              ? Text(_myReaction!, style: const TextStyle(fontSize: 22))
                              : HugeIcon(
                                  icon: HugeIcons.strokeRoundedFavourite,
                                  size: 22,
                                  color: _liked ? AppColors.red : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _formatCount(_likes),
                          key: ValueKey(_likes),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: (_liked || _myReaction != null)
                                ? AppColors.purple
                                : isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Comment
                GestureDetector(
                  onTap: () {
                    final id = _postId;
                    if (id != null && id.isNotEmpty) context.push('/post/$id');
                  },
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedMessage01,
                        size: 20,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(post.comments as int),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Share
                GestureDetector(
                  onTap: () {
                    final id = _postId;
                    final content = post.content as String? ?? '';
                    final text = content.isNotEmpty ? content : 'Check out this post on PartyPeople!';
                    Share.share(id != null && id.isNotEmpty
                        ? '$text\nhttps://partypeople.app/feed/$id'
                        : text);
                  },
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedShare01,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),

                const Spacer(),

                // Bookmark
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _bookmarked = !_bookmarked);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_bookmarked ? 'Post saved!' : 'Post removed from saved'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                  child: HugeIcon(
                    icon: _bookmarked ? HugeIcons.strokeRoundedBookmark02 : HugeIcons.strokeRoundedBookmark01,
                    size: 20,
                    color: _bookmarked ? AppColors.purple : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }
}

// ── Post Media Grid ───────────────────────────────────────────────────────────
class _PostMediaGrid extends StatelessWidget {
  final List<String> urls;
  final bool isDark;
  const _PostMediaGrid({required this.urls, required this.isDark});

  static const double _maxSingleHeight = 480;
  static const double _maxGridHeight = 320;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    final display = urls.take(4).toList();
    final isSingle = display.length == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isSingle
            ? _singleImage(display.first)
            : _grid(display),
      ),
    );
  }

  Widget _singleImage(String url) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: _maxSingleHeight),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                      : null,
                  color: AppColors.purple, strokeWidth: 2,
                )),
              ),
      ),
    );
  }

  Widget _grid(List<String> urls) {
    return SizedBox(
      height: _maxGridHeight,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: urls.asMap().entries.map((e) {
          final isLast = e.key == urls.length - 1 && urls.length == 4;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                e.value,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              ),
              if (isLast && urls.length == 4)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Text('+', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 220,
    color: AppColors.purple.withValues(alpha: 0.15),
    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 40, color: Colors.white38)),
  );
}
