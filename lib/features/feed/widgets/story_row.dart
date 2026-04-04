import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

// ── Background colors matching web ───────────────────────────────────────────
const _kBgColors = [
  Color(0xFF6C5CE7),
  Color(0xFFE040FB),
  Color(0xFF00CEC9),
  Color(0xFFFF8C42),
  Color(0xFFEF4444),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF3B82F6),
];

// ── Font styles matching web ──────────────────────────────────────────────────
const _kFontStyles = ['Bold', 'Serif', 'Italic', 'Mono', 'Thin', 'Script', 'Caps'];

TextStyle _storyTextStyle(String? fontStyle, {double size = 26, Color color = Colors.white}) {
  switch (fontStyle) {
    case 'Serif':   return TextStyle(fontSize: size, color: color, fontFamily: 'Georgia', fontWeight: FontWeight.w700);
    case 'Italic':  return TextStyle(fontSize: size, color: color, fontFamily: 'Georgia', fontStyle: FontStyle.italic, fontWeight: FontWeight.w700);
    case 'Mono':    return TextStyle(fontSize: size, color: color, fontFamily: 'monospace', fontWeight: FontWeight.w700, letterSpacing: 1);
    case 'Thin':    return TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w300, letterSpacing: 3);
    case 'Script':  return TextStyle(fontSize: size, color: color, letterSpacing: 1);
    case 'Caps':    return TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w800, letterSpacing: 4);
    default:        return TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w900);
  }
}

// Locally seen postIds (session-only)
final _seenIds = <String>{};

// ── Story Row ─────────────────────────────────────────────────────────────────
class StoryRow extends ConsumerStatefulWidget {
  const StoryRow({super.key});

  @override
  ConsumerState<StoryRow> createState() => _StoryRowState();
}

class _StoryRowState extends ConsumerState<StoryRow> {
  List<Map<String, dynamic>> _statuses = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getStatuses();
      final raw = res.data;
      final items = ((raw['data'] is List ? raw['data'] : raw['data']?['items']) as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _statuses = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (ctx, _, __) => _StoryViewer(
          statuses: _statuses,
          initialIndex: index,
          myUserId: ref.read(authProvider).user?.userId ?? '',
          onSeen: (id) {
            setState(() => _seenIds.add(id));
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _openComposer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StoryComposer(onPosted: (s) {
        setState(() => _statuses.insert(0, s));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = ref.watch(authProvider).user;

    return Container(
      height: 118,
      padding: const EdgeInsets.only(top: 6),
      child: _loading
          ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple)))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _statuses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _AddStoryButton(isDark: isDark, user: me, onTap: _openComposer);
                }
                final item = _statuses[index - 1];
                final postId = item['postId'] as String? ?? '';
                final seen = _seenIds.contains(postId);
                return _StoryBubble(
                  item: item,
                  seen: seen,
                  isDark: isDark,
                  onTap: () => _openViewer(index - 1),
                );
              },
            ),
    );
  }
}

// ── Add Story Button ──────────────────────────────────────────────────────────
class _AddStoryButton extends StatelessWidget {
  final bool isDark;
  final dynamic user;
  final VoidCallback onTap;
  const _AddStoryButton({required this.isDark, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final photo = user?.profilePhoto as String?;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: ClipOval(
                    child: photo != null
                        ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 34, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight))
                        : Icon(Icons.person_rounded, size: 34, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Your story', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

// ── Story Bubble ──────────────────────────────────────────────────────────────
class _StoryBubble extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool seen, isDark;
  final VoidCallback onTap;
  const _StoryBubble({required this.item, required this.seen, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final author = item['author'] as Map<String, dynamic>? ?? {};
    final name = (author['name'] as String? ?? '?').split(' ').first;
    final photo = author['profilePhoto'] as String?;
    final bgHex = item['bgColor'] as String?;
    final bgColor = bgHex != null ? Color(int.parse(bgHex.replaceFirst('#', 'FF'), radix: 16)) : _kBgColors[0];
    final media = (item['media'] as List?)?.cast<String>() ?? [];
    final content = item['content'] as String? ?? '';
    final role = author['role'] as String? ?? '';
    final isVenue = role == 'merchant';

    // Instagram-style gradient ring (orange→pink→purple) for unread
    const igRing = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFFF09433), Color(0xFFE6683C), Color(0xFFDC2743), Color(0xFFCC2366), Color(0xFFBC1888)],
    );

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88, height: 88,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: seen ? null : igRing,
                color: seen ? (isDark ? AppColors.borderDark : AppColors.borderLight) : null,
              ),
              child: Container(
                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? AppColors.bgDark : AppColors.bgLight),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: media.isNotEmpty
                      ? Image.network(media.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(photo, content, bgColor))
                      : (photo != null
                          ? Image.network(photo, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback(null, content, bgColor))
                          : _fallback(null, content, bgColor)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 88,
              child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                      color: seen
                          ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(String? photo, String content, Color bg) {
    if (photo != null) return Image.network(photo, fit: BoxFit.cover);
    return Container(
      color: bg,
      child: Center(
        child: Text(
          content.length > 4 ? content.substring(0, 4) : (content.isNotEmpty ? content : '✨'),
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Story Viewer ──────────────────────────────────────────────────────────────
class _StoryViewer extends StatefulWidget {
  final List<Map<String, dynamic>> statuses;
  final int initialIndex;
  final String myUserId;
  final void Function(String postId) onSeen;

  const _StoryViewer({required this.statuses, required this.initialIndex, required this.myUserId, required this.onSeen});

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

bool _isVideoUrl(String url) {
  final lower = url.toLowerCase();
  return lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.webm') || lower.contains('/video/');
}

class _StoryViewerState extends State<_StoryViewer> with SingleTickerProviderStateMixin {
  late int _index;
  late AnimationController _progress;
  List<Map<String, dynamic>> _viewers = [];
  bool _showViewers = false;
  bool _loadingViewers = false;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  static const _duration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _progress = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _startStory();
  }

  Future<void> _initVideo(String url) async {
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = c;
    try {
      await c.initialize();
      if (mounted) {
        setState(() => _videoInitialized = true);
        _progress.duration = c.value.duration;
        _progress.reset();
        _progress.forward();
        c.play();
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  void _startStory() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;

    final media = (_current['media'] as List?)?.cast<String>() ?? [];
    final hasVideo = media.isNotEmpty && _isVideoUrl(media.first);

    if (!hasVideo) {
      _progress.duration = _duration;
      _progress.reset();
      _progress.forward();
    } else {
      // Video duration will be set after init
      _progress.duration = _duration;
      _progress.reset();
      _initVideo(media.first);
    }

    _viewers = [];
    _showViewers = false;
    final postId = _current['postId'] as String? ?? '';
    if (postId.isNotEmpty) {
      ApiService().viewStatus(postId).ignore();
      // Defer onSeen so it doesn't trigger setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSeen(postId);
      });
      final myId = widget.myUserId;
      final authorId = (_current['author'] as Map?)?.get('userId') as String? ?? _current['userId'] as String? ?? '';
      if (myId == authorId) _loadViewers(postId);
    }
  }

  Future<void> _loadViewers(String postId) async {
    setState(() => _loadingViewers = true);
    try {
      final res = await ApiService().getStatusViewers(postId);
      final items = ((res.data['data']?['items'] ?? res.data['data']) as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _viewers = items; _loadingViewers = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingViewers = false);
    }
  }

  Map<String, dynamic> get _current => widget.statuses[_index];

  void _next() {
    if (_index < widget.statuses.length - 1) {
      setState(() => _index++);
      _startStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_index > 0) {
      setState(() => _index--);
      _startStory();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _current;
    final author = s['author'] as Map<String, dynamic>? ?? {};
    final authorName = author['name'] as String? ?? 'Unknown';
    final authorPhoto = author['profilePhoto'] as String?;
    final bgHex = s['bgColor'] as String?;
    final bgColor = bgHex != null
        ? Color(int.parse(bgHex.replaceFirst('#', 'FF'), radix: 16))
        : _kBgColors[_index % _kBgColors.length];
    final content = s['content'] as String? ?? '';
    final fontStyle = s['fontStyle'] as String?;
    final media = (s['media'] as List?)?.cast<String>() ?? [];
    final expiresAt = s['expiresAt'] as String?;
    final myId = widget.myUserId;
    final authorId = author['userId'] as String? ?? s['userId'] as String? ?? '';
    final isOwn = myId == authorId;

    String timeLeft = '';
    if (expiresAt != null) {
      try {
        final diff = DateTime.parse(expiresAt).difference(DateTime.now());
        final h = diff.inHours;
        timeLeft = h > 0 ? '${h}h left' : 'Expiring soon';
      } catch (_) {}
    }

    final screenSize = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final firstName2 = authorName.split(' ').first;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Background colour (text-only stories) ──────────────────────────
          Positioned.fill(child: Container(color: media.isEmpty ? bgColor : Colors.black)),

          // ── Full-screen media ──────────────────────────────────────────────
          if (media.isNotEmpty)
            Positioned.fill(
              child: _isVideoUrl(media.first)
                  ? (_videoInitialized && _videoController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                  : Image.network(media.first, fit: BoxFit.cover,
                      width: screenSize.width, height: screenSize.height,
                      errorBuilder: (_, __, ___) => const SizedBox()),
            ),

          // ── Top gradient scrim ─────────────────────────────────────────────
          if (media.isNotEmpty)
            Positioned(
              top: 0, left: 0, right: 0, height: 140,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0xBB000000), Colors.transparent],
                  ),
                ),
              ),
            ),

          // ── Bottom gradient scrim ──────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0, height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Centered text (text-only) ──────────────────────────────────────
          if (media.isEmpty && content.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(content, textAlign: TextAlign.center,
                    style: _storyTextStyle(fontStyle, size: 30)),
              ),
            ),

          // ── Text caption on media ──────────────────────────────────────────
          if (media.isNotEmpty && content.isNotEmpty)
            Positioned(
              bottom: isOwn ? 130 : 90,
              left: 20, right: 20,
              child: Text(content, textAlign: TextAlign.center,
                  style: _storyTextStyle(fontStyle, size: 20)),
            ),

          // ── Tap zones (left = prev, right = next) ─────────────────────────
          Positioned.fill(
            child: Row(
              children: [
                Expanded(child: GestureDetector(onTap: _prev, behavior: HitTestBehavior.translucent)),
                Expanded(child: GestureDetector(onTap: _next, behavior: HitTestBehavior.translucent)),
              ],
            ),
          ),

          // ── Progress bars ─────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8, right: 8,
            child: Row(
              children: List.generate(widget.statuses.length, (i) {
                return Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: i < _index
                        ? Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)))
                        : i == _index
                            ? AnimatedBuilder(
                                animation: _progress,
                                builder: (_, __) => FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progress.value,
                                  child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
                                ),
                              )
                            : const SizedBox(),
                  ),
                );
              }),
            ),
          ),

          // ── Author row ─────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            left: 12, right: 12,
            child: Row(
              children: [
                // IG-style gradient ring avatar
                Container(
                  width: 40, height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft, end: Alignment.topRight,
                      colors: [Color(0xFFF09433), Color(0xFFE6683C), Color(0xFFDC2743), Color(0xFFCC2366), Color(0xFFBC1888)],
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                    child: ClipOval(
                      child: authorPhoto != null
                          ? Image.network(authorPhoto, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 22))
                          : const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                      if (timeLeft.isNotEmpty)
                        Text(timeLeft,
                            style: const TextStyle(color: Colors.white70, fontSize: 11,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom bar: viewers (own) OR reply input ───────────────────────
          Positioned(
            bottom: safeBottom + 12,
            left: 12, right: 12,
            child: isOwn
                ? GestureDetector(
                    onTap: () => setState(() => _showViewers = !_showViewers),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.40),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Text('👁', style: TextStyle(fontSize: 15)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _loadingViewers
                                          ? 'Loading...'
                                          : '${_viewers.length} viewer${_viewers.length != 1 ? 's' : ''}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Icon(_showViewers ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white60, size: 20),
                                ],
                              ),
                              if (_showViewers && _viewers.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                ..._viewers.take(5).map((v) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 30, height: 30,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                                        child: ClipOval(
                                          child: v['profilePhoto'] != null
                                              ? Image.network(v['profilePhoto'], fit: BoxFit.cover)
                                              : const Icon(Icons.person, color: Colors.white, size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(v['name'] as String? ?? '',
                                          style: const TextStyle(color: Colors.white, fontSize: 13))),
                                    ],
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      // Reply text field (IG-style pill)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: TextField(
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Reply to $firstName2…',
                                    hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Quick reactions
                      ...['❤️', '🔥', '💜', '🎉'].map((e) => GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reacted $e'),
                                duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      )),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Story Composer ────────────────────────────────────────────────────────────
class _StoryComposer extends ConsumerStatefulWidget {
  final void Function(Map<String, dynamic> story) onPosted;
  const _StoryComposer({required this.onPosted});

  @override
  ConsumerState<_StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends ConsumerState<_StoryComposer> {
  final _ctrl = TextEditingController();
  Color _bg = _kBgColors[0];
  String _font = 'Bold';
  String? _mediaUrl;
  bool _posting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1280);
    if (xfile == null) return;
    try {
      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final res = await ApiService().uploadPostMedia(bytes, xfile.name, mime);
      final url = res.data['url'] as String? ?? '';
      if (url.isNotEmpty && mounted) setState(() => _mediaUrl = url);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _mediaUrl == null) return;
    setState(() => _posting = true);
    try {
      final hex = '#${_bg.value.toRadixString(16).substring(2).toUpperCase()}';
      final res = await ApiService().createPost({
        'content': text,
        'bgColor': hex,
        'fontStyle': _font,
        'type': 'status',
        if (_mediaUrl != null) 'media': [_mediaUrl],
      });
      final data = res.data['data'] ?? res.data['post'] ?? res.data;
      if (mounted) {
        Navigator.pop(context);
        widget.onPosted(data as Map<String, dynamic>? ?? {
          'postId': '',
          'content': text,
          'bgColor': hex,
          'fontStyle': _font,
          'media': _mediaUrl != null ? [_mediaUrl] : [],
          'author': {'name': ref.read(authProvider).user?.name ?? 'You', 'profilePhoto': ref.read(authProvider).user?.profilePhoto},
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to post story')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = _ctrl.text;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 180,
              decoration: BoxDecoration(
                color: _mediaUrl == null ? _bg : Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  if (_mediaUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(_mediaUrl!, fit: BoxFit.cover, width: double.infinity, height: 180),
                    ),
                  if (text.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(text, textAlign: TextAlign.center, style: _storyTextStyle(_font, size: 20)),
                      ),
                    ),
                  if (text.isEmpty && _mediaUrl == null)
                    Center(child: Text('Preview', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14))),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Text input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _ctrl,
                maxLength: 120,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                decoration: InputDecoration(
                  hintText: 'What\'s happening tonight?',
                  hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  filled: true,
                  fillColor: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                  counterStyle: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Color swatches (hidden when media selected)
            if (_mediaUrl == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _kBgColors.map((c) => GestureDetector(
                    onTap: () => setState(() => _bg = c),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bg == c ? Colors.white : Colors.transparent, width: 2.5),
                        boxShadow: _bg == c ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)] : null,
                      ),
                    ),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 10),

            // Font picker
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _kFontStyles.map((f) => GestureDetector(
                  onTap: () => setState(() => _font = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _font == f ? AppColors.purple : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _font == f ? AppColors.purple : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Text(f, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: _font == f ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Bottom actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Media button
                  GestureDetector(
                    onTap: _pickMedia,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _mediaUrl != null ? AppColors.purple : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ),
                      child: Icon(Icons.image_outlined, size: 20, color: _mediaUrl != null ? AppColors.purple : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ),
                  ),
                  // Remove media
                  if (_mediaUrl != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _mediaUrl = null),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppColors.red),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Post button
                  GestureDetector(
                    onTap: (_posting || (text.isEmpty && _mediaUrl == null)) ? null : _post,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        gradient: (text.isNotEmpty || _mediaUrl != null) ? AppColors.primaryGradient : null,
                        color: (text.isEmpty && _mediaUrl == null) ? (isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _posting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Share Story', style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: (text.isNotEmpty || _mediaUrl != null) ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Helper extension
extension _MapHelper on Map {
  dynamic get(String key) => this[key];
}
