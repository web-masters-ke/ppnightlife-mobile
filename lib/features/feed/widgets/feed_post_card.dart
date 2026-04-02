import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
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
  String? _myReaction;
  Map<String, int> _reactionCounts = {};
  late AnimationController _reactionPopController;
  late Animation<double> _reactionPopScale;
  bool _showReactionBar = false;
  bool _bookmarked = false;

  @override
  void initState() {
    super.initState();
    final likes = widget.post.likes as int;
    // Seed reactions from like count
    _reactionCounts = {
      if (likes > 0) '❤️': (likes * 0.4).round(),
      if (likes > 0) '🔥': (likes * 0.3).round(),
      if (likes > 0) '💜': (likes * 0.15).round(),
      if (likes > 0) '🎉': (likes * 0.1).round(),
    };
    _reactionPopController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _reactionPopScale = CurvedAnimation(parent: _reactionPopController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _reactionPopController.dispose();
    super.dispose();
  }

  String? get _postId {
    try { return widget.post.postId as String?; } catch (_) { return null; }
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

          // Media (images or video)
          if ((post.isImage as bool) || (post.isVideo as bool)) ...[
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
              isVideo: post.isVideo as bool,
              isDark: isDark,
            ),
          ],


          // ── Emoji picker (shown when React tapped) ───────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: _showReactionBar
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: ScaleTransition(
                      scale: _reactionPopScale,
                      child: Wrap(
                        spacing: 4,
                        children: _reactions.map((r) {
                          final isActive = _myReaction == r.$1;
                          final count = _reactionCounts[r.$1] ?? 0;
                          return GestureDetector(
                            onTap: () => _onReactionTap(r.$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.purple.withValues(alpha: 0.15)
                                    : isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isActive
                                      ? AppColors.purple.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(r.$1, style: TextStyle(fontSize: isActive ? 22 : 20)),
                                  if (count > 0) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatCount(count),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.purple,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Action bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                // React — icon + count
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showReactionBar = !_showReactionBar);
                    if (_showReactionBar) {
                      _reactionPopController.forward(from: 0);
                    } else {
                      _reactionPopController.reverse();
                    }
                  },
                  child: Row(
                    children: [
                      _myReaction != null
                          ? Text(_myReaction!, style: const TextStyle(fontSize: 18, height: 1))
                          : HugeIcon(
                              icon: HugeIcons.strokeRoundedFavourite,
                              size: 20,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                      const SizedBox(width: 5),
                      Text(
                        _formatCount(_reactionCounts.values.fold(0, (a, b) => a + b)),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _myReaction != null
                              ? AppColors.purple
                              : isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Comment — icon + count
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
                      const SizedBox(width: 5),
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
                const SizedBox(width: 20),

                // Share — icon only
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

                // Bookmark — icon only, right-aligned
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
                    icon: _bookmarked
                        ? HugeIcons.strokeRoundedBookmark02
                        : HugeIcons.strokeRoundedBookmark01,
                    size: 20,
                    color: _bookmarked
                        ? AppColors.orange
                        : isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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


// ── Inline video player — thumbnail first, loads only on tap ─────────────────
// Shows a static thumbnail instantly with no network cost.
// Video controller is only created when the user taps play — zero preloading.
// Controller is disposed when the widget leaves the tree (scroll away = free memory).
class _FeedVideoPlayer extends StatefulWidget {
  final String url;
  const _FeedVideoPlayer({required this.url});
  @override
  State<_FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<_FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = false;   // initialising the controller
  bool _playing = false;   // controller ready + playing
  bool _error   = false;
  bool _muted   = false;

  // Thumbnail = video URL with an ?thumb query param stripped (S3 videos serve
  // their own first frame) or we just show a dark placeholder immediately.
  // Either way we show SOMETHING before any network call.

  Future<void> _startPlayback() async {
    if (_loading || _playing) return;
    setState(() { _loading = true; _error = false; });
    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = c;
      await c.initialize();
      if (!mounted) { c.dispose(); return; }
      await c.setLooping(true);
      await c.setVolume(_muted ? 0 : 1);
      await c.play();
      setState(() { _playing = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() { c.value.isPlaying ? c.pause() : c.play(); });
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Error state ──────────────────────────────────────────────────────
    if (_error) {
      return Container(
        height: 260,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 36),
              SizedBox(height: 8),
              Text('Could not load video', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    // ── Thumbnail / not-yet-started ──────────────────────────────────────
    if (!_playing) {
      return GestureDetector(
        onTap: _startPlayback,
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Try to show thumbnail — silently fails for raw video URLs
              CachedNetworkImage(
                imageUrl: widget.url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
              Container(color: Colors.black.withValues(alpha: 0.30)),
              Center(
                child: _loading
                    ? const SizedBox(
                        width: 44, height: 44,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Container(
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(14),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Playing ──────────────────────────────────────────────────────────
    final c = _controller!;
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) => GestureDetector(
        onTap: _togglePlay,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width > 0 ? c.value.size.width : 9,
                height: c.value.size.height > 0 ? c.value.size.height : 16,
                child: VideoPlayer(c),
              ),
            ),
            if (!c.value.isPlaying)
              Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
              ),
            // Mute toggle — bottom right
            Positioned(
              bottom: 12, right: 12,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(
                    _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white, size: 18,
                  ),
                ),
              ),
            ),
            // Scrubable progress bar at bottom
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: VideoProgressIndicator(
                c, allowScrubbing: true, padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: AppColors.purple,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Post Media Grid ───────────────────────────────────────────────────────────
class _PostMediaGrid extends StatelessWidget {
  final List<String> urls;
  final bool isDark;
  final bool isVideo;
  const _PostMediaGrid({required this.urls, required this.isDark, this.isVideo = false});

  static const double _maxSingleHeight = 480;
  static const double _maxGridHeight = 320;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    // Video post — Instagram-style: edge-to-edge, no border radius, 4:5 aspect ratio
    if (isVideo) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: _FeedVideoPlayer(url: urls.first),
      );
    }

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
