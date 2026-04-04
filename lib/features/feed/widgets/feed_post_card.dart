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

  String? get _userId {
    try { return widget.post.userId as String?; } catch (_) { return null; }
  }

  void _openUserProfile() {
    final uid = _userId;
    if (uid != null && uid.isNotEmpty) context.push('/user/$uid');
  }

  void _openPostDetail() {
    final id = _postId;
    if (id != null && id.isNotEmpty) context.push('/post/$id');
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
                GestureDetector(
                  onTap: _openUserProfile,
                  child: Stack(
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
                ),  // GestureDetector (avatar)
                const SizedBox(width: 10),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _openUserProfile,
                            child: Text(
                              post.username as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
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
                  onTap: _openPostDetail,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedMoreHorizontal,
                    size: 20,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          // Content
          if ((post.content as String).isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _openPostDetail,
              child: Padding(
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
            ),
          ],

          // Media (images or video)
          if ((post.isImage as bool) || (post.isVideo as bool)) ...[
            if ((post.content as String).isNotEmpty) const SizedBox(height: 10),
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
                  onTap: _openPostDetail,
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


// ── Inline video player — Instagram-style: auto-initialises immediately, muted ─
// Controller initialises as soon as the widget is built (like Instagram).
// Plays muted by default; user taps to unmute/pause.
// Disposed when widget leaves the tree.
class _FeedVideoPlayer extends StatefulWidget {
  final String url;
  const _FeedVideoPlayer({required this.url});
  @override
  State<_FeedVideoPlayer> createState() => _FeedVideoPlayerState();
}

class _FeedVideoPlayerState extends State<_FeedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error       = false;
  bool _muted       = true;   // start muted like Instagram

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _controller = c;
      await c.initialize();
      if (!mounted) { c.dispose(); return; }
      await c.setLooping(true);
      await c.setVolume(0); // muted start
      await c.play();
      setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller?.setVolume(_muted ? 0 : 1);
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() { c.value.isPlaying ? c.pause() : c.play(); });
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
        color: Colors.black,
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 36),
            SizedBox(height: 8),
            Text('Could not load video', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      );
    }

    // ── Loading — show black with spinner while controller initialises ───
    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: SizedBox(
            width: 36, height: 36,
            child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
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
            // Video fills the 4:5 frame, cover-cropped
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width:  c.value.size.width  > 0 ? c.value.size.width  : 9,
                height: c.value.size.height > 0 ? c.value.size.height : 16,
                child: VideoPlayer(c),
              ),
            ),
            // Pause indicator — only visible when paused
            if (!c.value.isPlaying)
              Container(
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              ),
            // Mute toggle — bottom right corner
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
            // Progress bar at bottom
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

// ── Adaptive single image — resolves natural dimensions, clamps ratio ────────
class _AdaptiveImage extends StatefulWidget {
  final String url;
  final double width;
  const _AdaptiveImage({required this.url, required this.width});

  @override
  State<_AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<_AdaptiveImage> {
  double? _aspectRatio; // width / height

  @override
  void initState() {
    super.initState();
    _resolveAspectRatio();
  }

  void _resolveAspectRatio() {
    final image = NetworkImage(widget.url);
    final stream = image.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((info, _) {
      if (mounted) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0) setState(() => _aspectRatio = w / h);
      }
    }, onError: (_, __) {
      if (mounted) setState(() => _aspectRatio = 4 / 5); // fallback
    });
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    // Clamp: min square (1:1 = ratio 1.0), max portrait (4:5 = ratio 0.8)
    final ratio = (_aspectRatio ?? 0.9).clamp(0.8, 1.91);
    final height = widget.width / ratio;
    return SizedBox(
      width: widget.width,
      height: height,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Container(
          width: widget.width,
          height: height,
          color: const Color(0xFF141420),
        ),
        errorWidget: (_, __, ___) => Container(
          width: widget.width,
          height: height,
          color: AppColors.purple.withValues(alpha: 0.15),
          child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 40, color: Colors.white38)),
        ),
      ),
    );
  }
}

// ── Post Media Grid ───────────────────────────────────────────────────────────
// Instagram-style: full-width, no horizontal padding, no border radius.
// Single/video: adaptive aspect ratio (min 1:1, max 4:5). Multi: grid with 2px gaps.
class _PostMediaGrid extends StatelessWidget {
  final List<String> urls;
  final bool isDark;
  final bool isVideo;
  const _PostMediaGrid({required this.urls, required this.isDark, this.isVideo = false});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    final w = MediaQuery.of(context).size.width;

    // ── Video — 4:5 portrait, edge-to-edge, auto-plays muted ────────────
    if (isVideo) {
      return SizedBox(
        width: w,
        height: w * 5 / 4,
        child: _FeedVideoPlayer(url: urls.first),
      );
    }

    final display = urls.take(4).toList();

    // ── Single image — adaptive aspect ratio ────────────────────────────
    if (display.length == 1) {
      return _AdaptiveImage(url: display.first, width: w);
    }

    // ── 2 images — side by side, square each ────────────────────────────
    if (display.length == 2) {
      final h = w / 2;
      return SizedBox(
        width: w, height: h,
        child: Row(children: [
          SizedBox(width: (w - 2) / 2, height: h, child: _img(display[0])),
          const SizedBox(width: 2),
          SizedBox(width: (w - 2) / 2, height: h, child: _img(display[1])),
        ]),
      );
    }

    // ── 3 images — tall left + 2 stacked right ───────────────────────────
    if (display.length == 3) {
      final h = w * 0.65;
      final rightW = (w - 2) / 3;
      final leftW  = w - rightW - 2;
      return SizedBox(
        width: w, height: h,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: leftW, child: _img(display[0])),
          const SizedBox(width: 2),
          SizedBox(
            width: rightW,
            child: Column(children: [
              SizedBox(height: (h - 2) / 2, child: _img(display[1])),
              const SizedBox(height: 2),
              SizedBox(height: (h - 2) / 2, child: _img(display[2])),
            ]),
          ),
        ]),
      );
    }

    // ── 4 images — 2×2 grid ──────────────────────────────────────────────
    final cell = (w - 2) / 2;
    return SizedBox(
      width: w, height: cell * 2 + 2,
      child: Column(children: [
        Row(children: [
          SizedBox(width: cell, height: cell, child: _img(display[0])),
          const SizedBox(width: 2),
          SizedBox(width: cell, height: cell, child: _img(display[1])),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          SizedBox(width: cell, height: cell, child: _img(display[2])),
          const SizedBox(width: 2),
          SizedBox(
            width: cell, height: cell,
            child: Stack(fit: StackFit.expand, children: [
              _img(display[3]),
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Text('+', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _img(String url) => CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    placeholder: (_, __) => Container(color: const Color(0xFF141420)),
    errorWidget: (_, __, ___) => Container(
      color: AppColors.purple.withValues(alpha: 0.15),
      child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedImage01, size: 40, color: Colors.white38)),
    ),
  );
}
