import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class DjRoomScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> dj;
  const DjRoomScreen({super.key, required this.dj});

  @override
  ConsumerState<DjRoomScreen> createState() => _DjRoomScreenState();
}

class _DjRoomScreenState extends ConsumerState<DjRoomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  List<Map<String, dynamic>> _queue = [];
  bool _loadingQueue = true;
  bool _submitting = false;
  Timer? _refreshTimer;

  final _songCtrl = TextEditingController();
  final _artistCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _loadQueue();
    // Auto-refresh queue every 15 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadQueue());
  }

  @override
  void dispose() {
    _tc.dispose();
    _songCtrl.dispose();
    _artistCtrl.dispose();
    _noteCtrl.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  String get _djId =>
      widget.dj['djId'] as String? ??
      widget.dj['userId'] as String? ??
      widget.dj['id'] as String? ?? '';

  String get _venueId =>
      (widget.dj['venue'] as Map?)?['venueId'] as String? ??
      (widget.dj['venue'] as Map?)?['id'] as String? ??
      widget.dj['venueId'] as String? ?? '';

  Future<void> _loadQueue() async {
    try {
      final res = await ApiService().getDJQueue(venueId: _venueId.isNotEmpty ? _venueId : null);
      final data = res.data['data'];
      final items = ((data is List ? data : data?['items']) as List? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() { _queue = items; _loadingQueue = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingQueue = false);
    }
  }

  Future<void> _requestSong() async {
    final song = _songCtrl.text.trim();
    if (song.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    try {
      await ApiService().requestSong({
        'songTitle': song,
        'artistName': _artistCtrl.text.trim(),
        'note': _noteCtrl.text.trim(),
        if (_venueId.isNotEmpty) 'venueId': _venueId,
        if (_djId.isNotEmpty) 'djId': _djId,
      });
      _songCtrl.clear();
      _artistCtrl.clear();
      _noteCtrl.clear();
      FocusScope.of(context).unfocus();
      await _loadQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Song requested! 🎵'),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('DioException', '').trim()),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _vote(String requestId, String type) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService().voteSongRequest(requestId, type);
      _loadQueue();
    } catch (_) {}
  }

  void _showTipSheet(String requestId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TipSheet(
        isDark: isDark,
        onTip: (amount) async {
          Navigator.pop(context);
          try {
            await ApiService().tipDJ(requestId, amount);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Tipped KES $amount 💜'),
                backgroundColor: AppColors.purple,
                behavior: SnackBarBehavior.floating,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tip failed. Check your wallet balance.'),
                backgroundColor: AppColors.red,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dj = widget.dj;
    final name = dj['djName'] as String? ?? dj['name'] as String? ?? 'DJ';
    final venueName = (dj['venue'] as Map?)?['name'] as String? ?? dj['venueName'] as String? ?? '';
    final photo = dj['profilePhoto'] as String?;
    final checkins = (dj['checkinCount'] ?? dj['guestCount'] ?? 0) as int;
    final nowPlaying = dj['nowPlaying'] as String?;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgDark,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 22, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background
                  if (photo != null)
                    Image.network(photo, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gradientBg(name))
                  else
                    _gradientBg(name),
                  // Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  // DJ info
                  Positioned(
                    left: 16, right: 16, bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LIVE badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(6)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                        if (venueName.isNotEmpty)
                          Row(children: [
                            const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(venueName, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 13, color: Colors.white60),
                          const SizedBox(width: 4),
                          Text('$checkins in the crowd', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                        ]),
                        if (nowPlaying != null && nowPlaying.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 13, color: Colors.white),
                              const SizedBox(width: 6),
                              Flexible(child: Text('Now playing: $nowPlaying',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tc,
              indicatorColor: AppColors.purple,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'Request a Song'),
                Tab(text: 'Song Queue'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tc,
          children: [
            _RequestTab(
              songCtrl: _songCtrl,
              artistCtrl: _artistCtrl,
              noteCtrl: _noteCtrl,
              submitting: _submitting,
              isDark: isDark,
              onSubmit: _requestSong,
            ),
            _QueueTab(
              queue: _queue,
              loading: _loadingQueue,
              isDark: isDark,
              onVote: _vote,
              onTip: _showTipSheet,
              onRefresh: _loadQueue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBg(String name) {
    final gradients = [AppColors.primaryGradient, AppColors.warmGradient, AppColors.cyanGradient];
    final grad = gradients[name.hashCode.abs() % gradients.length];
    return Container(decoration: BoxDecoration(gradient: grad),
        child: const Center(child: Text('🎧', style: TextStyle(fontSize: 80))));
  }
}

// ── Request Tab ───────────────────────────────────────────────────────────────
class _RequestTab extends StatelessWidget {
  final TextEditingController songCtrl, artistCtrl, noteCtrl;
  final bool submitting, isDark;
  final VoidCallback onSubmit;

  const _RequestTab({
    required this.songCtrl, required this.artistCtrl, required this.noteCtrl,
    required this.submitting, required this.isDark, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 28, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Request a Song', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                const Text('Send your request to the DJ', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          _label('Song Title *', isDark),
          const SizedBox(height: 6),
          _field(songCtrl, 'e.g. Afrobeats All Night', isDark),
          const SizedBox(height: 14),

          _label('Artist Name', isDark),
          const SizedBox(height: 6),
          _field(artistCtrl, 'e.g. Burna Boy', isDark),
          const SizedBox(height: 14),

          _label('Note to DJ (optional)', isDark),
          const SizedBox(height: 6),
          _field(noteCtrl, 'e.g. This one is for my birthday!', isDark, maxLines: 3),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: submitting ? null : onSubmit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: submitting ? null : AppColors.primaryGradient,
                  color: submitting ? (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight) : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: submitting
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedSent, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Send Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(text, style: TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  ));

  Widget _field(TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        filled: true,
        fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}

// ── Queue Tab ─────────────────────────────────────────────────────────────────
class _QueueTab extends StatelessWidget {
  final List<Map<String, dynamic>> queue;
  final bool loading, isDark;
  final void Function(String id, String type) onVote;
  final void Function(String id) onTip;
  final Future<void> Function() onRefresh;

  const _QueueTab({
    required this.queue, required this.loading,
    required this.isDark, required this.onVote, required this.onTip,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));

    if (queue.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.purple,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          Center(child: Column(children: [
            const Text('🎵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Queue is empty', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            )),
            const SizedBox(height: 6),
            Text('Be the first to request a song!', style: TextStyle(
              fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            )),
          ])),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.purple,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: queue.length,
        itemBuilder: (ctx, i) {
          final req = queue[i];
          final reqId = req['requestId'] as String? ?? req['_id'] as String? ?? '';
          final song = req['songTitle'] as String? ?? req['song'] as String? ?? '?';
          final artist = req['artistName'] as String? ?? req['artist'] as String? ?? '';
          final note = req['note'] as String? ?? '';
          final status = req['status'] as String? ?? 'pending';
          final votes = (req['votes'] as num?)?.toInt() ?? 0;
          final requester = req['requester'] as Map<String, dynamic>? ?? {};
          final requesterName = requester['name'] as String? ?? 'Anonymous';
          final isPlaying = status == 'playing';
          final isCompleted = status == 'completed';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isPlaying
                  ? AppColors.purple.withOpacity(0.12)
                  : isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPlaying
                    ? AppColors.purple.withOpacity(0.4)
                    : isCompleted
                        ? AppColors.green.withOpacity(0.3)
                        : isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                // Position badge
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: isPlaying ? AppColors.primaryGradient : null,
                    color: isPlaying ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isPlaying
                        ? const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 16, color: Colors.white)
                        : isCompleted
                            ? const Icon(Icons.check, size: 16, color: AppColors.green)
                            : Text('${i + 1}', style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(song, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ))),
                      if (isPlaying)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(4)),
                          child: const Text('PLAYING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                          child: const Text('DONE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.green)),
                        ),
                    ]),
                    if (artist.isNotEmpty)
                      Text(artist, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    if (note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('"$note"', style: TextStyle(
                          fontSize: 11, fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        )),
                      ),
                    const SizedBox(height: 6),
                    Text('by $requesterName', style: TextStyle(fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                  ]),
                ),
                const SizedBox(width: 8),
                // Actions column
                Column(
                  children: [
                    // Vote up
                    GestureDetector(
                      onTap: reqId.isNotEmpty ? () => onVote(reqId, 'up') : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedThumbsUp, size: 16, color: AppColors.purple),
                          Text('$votes', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.purple)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Tip
                    GestureDetector(
                      onTap: reqId.isNotEmpty ? () => onTip(reqId) : null,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const HugeIcon(icon: HugeIcons.strokeRoundedMoneySend02, size: 16, color: AppColors.pink),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Tip Sheet ─────────────────────────────────────────────────────────────────
class _TipSheet extends StatelessWidget {
  final bool isDark;
  final void Function(int) onTip;

  const _TipSheet({required this.isDark, required this.onTip});

  static const _amounts = [50, 100, 200, 500, 1000];

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: EdgeInsets.fromLTRB(16, 16, 16, botPad > 0 ? botPad + 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgElevatedDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          const Text('💜 Tip the DJ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Send a tip from your wallet to boost this request', style: TextStyle(
            fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          )),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: _amounts.map((a) => GestureDetector(
              onTap: () => onTip(a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text('KES $a', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
