import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class DJScreen extends ConsumerStatefulWidget {
  const DJScreen({super.key});

  @override
  ConsumerState<DJScreen> createState() => _DJScreenState();
}

class _DJScreenState extends ConsumerState<DJScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() => _currentTab = _tabController.index);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgCardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        title: Row(
          children: [
            const Text('🎧', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'DJ Studio',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              size: 22,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.pink,
          unselectedLabelColor:
              isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          indicatorColor: AppColors.pink,
          indicatorWeight: 2,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          dividerColor:
              isDark ? AppColors.borderDark : AppColors.borderLight,
          tabs: const [
            Tab(text: 'Live Set'),
            Tab(text: 'Request Queue'),
            Tab(text: 'Earnings'),
            Tab(text: 'Stats'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LiveSetTab(isDark: isDark, user: user),
          _RequestQueueTab(isDark: isDark),
          _EarningsTab(isDark: isDark),
          _StatsTab(isDark: isDark, user: user),
          _SettingsTab(isDark: isDark, user: user),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE SET TAB
// ─────────────────────────────────────────────────────────────────────────────
class _LiveSetTab extends StatefulWidget {
  final bool isDark;
  final dynamic user;
  const _LiveSetTab({required this.isDark, required this.user});

  @override
  State<_LiveSetTab> createState() => _LiveSetTabState();
}

class _LiveSetTabState extends State<_LiveSetTab> {
  bool _isLive = false;
  bool _goingLive = false;
  String? _selectedVenueName;
  String? _selectedVenueId;
  int _innerTab = 0; // 0=Queue 1=Playlist 2=External
  double _volume = 0.75;
  bool _playing = false;
  List<Map<String, dynamic>> _venues = [];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    try {
      final res = await ApiService().getVenues(limit: 20);
      final items = (res.data['data']['items'] as List?) ?? [];
      setState(() {
        _venues = items.cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _toggleLive() async {
    if (!_isLive && _selectedVenueId == null) {
      _showVenuePicker();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _goingLive = true);
    try {
      if (_isLive) {
        await ApiService().endSet();
        setState(() { _goingLive = false; _isLive = false; });
      } else {
        await ApiService().goLive(_selectedVenueId!);
        setState(() { _goingLive = false; _isLive = true; });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isLive
              ? '🔴 You are now LIVE at $_selectedVenueName!'
              : '⏹ Live session ended.'),
          backgroundColor: _isLive ? AppColors.red : AppColors.textMutedDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _goingLive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.red,
        ));
      }
    }
  }

  void _showVenuePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = widget.isDark;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgElevatedDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Venue',
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight)),
              const SizedBox(height: 4),
              Text('Where are you performing tonight?',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight)),
              const SizedBox(height: 16),
              if (_venues.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No venues available', style: TextStyle(color: AppColors.textMutedDark)),
                )),
              ..._venues.map((venue) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVenueName = venue['name'] as String? ?? 'Unknown';
                        _selectedVenueId = venue['venueId'] as String? ?? '';
                      });
                      Navigator.pop(context);
                      _toggleLive();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.bgCardDark
                            : AppColors.bgElevatedLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Text('🏛️',
                              style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 10),
                          Text(venue['name'] as String? ?? 'Venue',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Go Live Card ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: _isLive
                  ? const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)])
                  : AppColors.warmGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:
                      (_isLive ? AppColors.red : AppColors.orange).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle),
                      child: const Center(
                          child: Text('🎧',
                              style: TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.user?.name ?? 'DJ',
                              style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          Text(
                              _isLive
                                  ? '🔴 Live at $_selectedVenueName'
                                  : _selectedVenueName != null
                                      ? 'Ready at $_selectedVenueName'
                                      : 'Select venue to go live',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    if (_isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('142 👥',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _toggleLive,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: _goingLive
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(
                                  icon: _isLive
                                      ? HugeIcons.strokeRoundedStop
                                      : HugeIcons.strokeRoundedRadio,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isLive
                                      ? 'End Live Session'
                                      : 'Go Live Now',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Now Playing ───────────────────────────────────────────────────
          _SectionTitle('Now Playing', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                          gradient: AppColors.warmGradient,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('🎵',
                              style: TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Essence - Wizkid ft. Tems',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                          Text('Afrobeats · 4:12',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPrevious,
                              size: 22,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _playing = !_playing),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                                gradient: AppColors.warmGradient,
                                shape: BoxShape.circle),
                            child: Center(
                              child: HugeIcon(
                                icon: _playing
                                    ? HugeIcons.strokeRoundedPause
                                    : HugeIcons.strokeRoundedPlay,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {},
                          child: HugeIcon(
                              icon: HugeIcons.strokeRoundedNext,
                              size: 22,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.45,
                    backgroundColor: isDark
                        ? AppColors.bgElevatedDark
                        : AppColors.bgElevatedLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.pink),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1:54',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                    Text('4:12',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                  ],
                ),
                const SizedBox(height: 10),
                // Volume
                Row(
                  children: [
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedVolumeLow,
                        size: 16,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7),
                          overlayShape: SliderComponentShape.noOverlay,
                          activeTrackColor: AppColors.pink,
                          inactiveTrackColor: isDark
                              ? AppColors.bgElevatedDark
                              : AppColors.bgElevatedLight,
                          thumbColor: AppColors.pink,
                        ),
                        child: Slider(
                          value: _volume,
                          onChanged: (v) => setState(() => _volume = v),
                        ),
                      ),
                    ),
                    HugeIcon(
                        icon: HugeIcons.strokeRoundedVolumeHigh,
                        size: 16,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Queue / Playlist / External tabs ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: ['Queue', 'Playlist', 'External']
                  .asMap()
                  .entries
                  .map((e) => Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _innerTab = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              gradient: _innerTab == e.key
                                  ? AppColors.warmGradient
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _innerTab == e.key
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: _innerTab == e.key
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          if (_innerTab == 0) _QueuePanel(isDark: isDark),
          if (_innerTab == 1) _PlaylistPanel(isDark: isDark),
          if (_innerTab == 2) _ExternalPanel(isDark: isDark),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Queue Panel ───────────────────────────────────────────────────────────────
class _QueuePanel extends StatefulWidget {
  final bool isDark;
  const _QueuePanel({required this.isDark});

  @override
  State<_QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends State<_QueuePanel> {
  final List<_Req> _queue = [];

  void _act(int i, String action) {
    HapticFeedback.selectionClick();
    setState(() {
      if (action == 'remove') {
        _queue.removeAt(i);
      } else {
        _queue[i] = _Req(
          song: _queue[i].song,
          requester: _queue[i].requester,
          tip: _queue[i].tip,
          votes: _queue[i].votes,
          status: action,
          reqId: _queue[i].reqId,
        );
      }
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, item);
    });
    try {
      final ids = _queue.map((r) => r.reqId).where((id) => id.isNotEmpty).toList();
      if (ids.isNotEmpty) await ApiService().reorderQueue(ids);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text('🎵', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('No requests yet',
                  style: TextStyle(
                      fontSize: 14,
                      color: widget.isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight)),
            ],
          ),
        ),
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _onReorder,
      proxyDecorator: (child, _, animation) => Material(color: Colors.transparent, child: child),
      children: _queue.asMap().entries.map((e) {
        final r = e.value;
        final isPlaying = r.status == 'playing';
        return Container(
          key: ValueKey('req_${e.key}_${r.song}'),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.pink.withOpacity(0.08)
                : (widget.isDark ? AppColors.bgCardDark : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying
                  ? AppColors.pink.withOpacity(0.3)
                  : (widget.isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.song,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: widget.isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight)),
                    Text('by ${r.requester}  ·  ${r.votes} votes',
                        style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight)),
                    if (r.tip > 0)
                      Text('KES ${r.tip} tip',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cyan)),
                  ],
                ),
              ),
              if (r.status == 'pending') ...[
                _IconBtn(HugeIcons.strokeRoundedPlay, AppColors.green,
                    () => _act(e.key, 'playing')),
                const SizedBox(width: 6),
                _IconBtn(HugeIcons.strokeRoundedCheckmarkCircle01,
                    AppColors.cyan, () => _act(e.key, 'accepted')),
                const SizedBox(width: 6),
                _IconBtn(HugeIcons.strokeRoundedCancel01, AppColors.red,
                    () => _act(e.key, 'remove')),
              ] else if (r.status == 'playing') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('NOW PLAYING',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 6),
                _IconBtn(HugeIcons.strokeRoundedStop, AppColors.red,
                    () => _act(e.key, 'remove')),
              ] else
                _IconBtn(HugeIcons.strokeRoundedCancel01,
                    AppColors.textMutedDark, () => _act(e.key, 'remove')),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Playlist Panel ────────────────────────────────────────────────────────────
class _PlaylistPanel extends StatefulWidget {
  final bool isDark;
  const _PlaylistPanel({required this.isDark});

  @override
  State<_PlaylistPanel> createState() => _PlaylistPanelState();
}

class _PlaylistPanelState extends State<_PlaylistPanel> {
  List<_Track> _tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getDJPlaylist();
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() {
        _tracks = items.map((t) => _Track(
          trackId: t['trackId'] as String? ?? t['_id'] as String? ?? '',
          title: t['title'] as String? ?? 'Unknown',
          artist: t['artist'] as String? ?? '',
          duration: t['duration'] as String? ?? '--:--',
          genre: t['genre'] as String? ?? '',
        )).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _tracks = []; _loading = false; });
    }
  }

  Future<void> _deleteTrack(int i) async {
    final track = _tracks[i];
    setState(() => _tracks.removeAt(i));
    if (track.trackId.isNotEmpty) {
      try {
        await ApiService().deleteDJTrack(track.trackId);
      } catch (_) {
        if (mounted) setState(() => _tracks.insert(i, track));
      }
    }
  }

  Future<void> _uploadTrack() async {
    final isDark = widget.isDark;
    final titleCtrl = TextEditingController();
    final artistCtrl = TextEditingController();
    final genreCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgElevatedDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Add to Playlist', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 16),
              _buildSheetField(ctx, titleCtrl, 'Song Title', isDark),
              const SizedBox(height: 10),
              _buildSheetField(ctx, artistCtrl, 'Artist', isDark),
              const SizedBox(height: 10),
              _buildSheetField(ctx, genreCtrl, 'Genre', isDark),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final title = titleCtrl.text.trim();
                  final artist = artistCtrl.text.trim();
                  if (title.isEmpty || artist.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final res = await ApiService().selfAddSong({
                      'title': title,
                      'artist': artist,
                      'genre': genreCtrl.text.trim(),
                    });
                    final m = res.data['data'] ?? res.data;
                    setState(() {
                      _tracks.insert(0, _Track(
                        title: m['title'] as String? ?? title,
                        artist: m['artist'] as String? ?? artist,
                        genre: m['genre'] as String? ?? genreCtrl.text.trim(),
                        duration: m['duration'] as String? ?? '--',
                        trackId: m['trackId'] ?? m['_id'] ?? '',
                      ));
                    });
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('"$title" added to playlist'), behavior: SnackBarBehavior.floating));
                  } catch (_) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add track'), behavior: SnackBarBehavior.floating));
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('Add Track', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    artistCtrl.dispose();
    genreCtrl.dispose();
  }

  Widget _buildSheetField(BuildContext context, TextEditingController ctrl, String hint, bool isDark) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        filled: true,
        fillColor: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _load,
      child: ListView(
        children: [
          GestureDetector(
            onTap: _uploadTrack,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Upload Track (MP3, WAV, AAC)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._tracks.asMap().entries.map((e) {
            final isPlaying = e.key == 0;
            final t = e.value;
            return Dismissible(
              key: Key(t.trackId.isNotEmpty ? t.trackId : '${e.key}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 20, color: AppColors.red),
              ),
              onDismissed: (_) => _deleteTrack(e.key).ignore(),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.pink.withOpacity(0.08)
                      : (isDark ? AppColors.bgCardDark : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPlaying
                        ? AppColors.pink.withOpacity(0.3)
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: isPlaying
                          ? const HugeIcon(icon: HugeIcons.strokeRoundedPause, size: 16, color: AppColors.pink)
                          : Text('${e.key + 1}', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ),
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        gradient: isPlaying ? AppColors.warmGradient : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text('🎵', style: TextStyle(fontSize: 16))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isPlaying ? AppColors.pink : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
                          Text(t.artist, style: TextStyle(fontSize: 11,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                        ],
                      ),
                    ),
                    Text(t.duration, style: TextStyle(fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteTrack(e.key).ignore(),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 16,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── External Panel ────────────────────────────────────────────────────────────
class _ExternalPanel extends StatefulWidget {
  final bool isDark;
  const _ExternalPanel({required this.isDark});

  @override
  State<_ExternalPanel> createState() => _ExternalPanelState();
}

class _ExternalPanelState extends State<_ExternalPanel> {
  int _srcType = 0; // 0=YouTube 1=SoundCloud 2=Direct URL
  final _urlCtrl = TextEditingController();

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sources = ['YouTube', 'SoundCloud', 'Direct URL'];
    return Column(
      children: [
        Row(
          children: sources.asMap().entries.map((e) {
            final sel = _srcType == e.key;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _srcType = e.key),
                child: Container(
                  margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color: sel
                        ? null
                        : (isDark
                            ? AppColors.bgElevatedDark
                            : AppColors.bgElevatedLight),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel
                            ? Colors.transparent
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight)),
                  ),
                  child: Text(e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight))),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlCtrl,
          style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: _srcType == 0
                ? 'Paste YouTube URL...'
                : _srcType == 1
                    ? 'Paste SoundCloud URL...'
                    : 'Paste direct audio URL (MP3/AAC)...',
            hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedLink01,
                size: 18,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight),
            filled: true,
            fillColor:
                isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.purple)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    size: 18,
                    color: Colors.white),
                SizedBox(width: 6),
                Text('Load & Play',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST QUEUE TAB
// ─────────────────────────────────────────────────────────────────────────────
class _RequestQueueTab extends StatefulWidget {
  final bool isDark;
  const _RequestQueueTab({required this.isDark});

  @override
  State<_RequestQueueTab> createState() => _RequestQueueTabState();
}

class _RequestQueueTabState extends State<_RequestQueueTab> {
  int _filter = 0; // 0=pending 1=accepted 2=playing 3=rejected
  List<Map<String, dynamic>> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    try {
      final res = await ApiService().getDJQueue();
      final items = (res.data['data']['items'] as List?) ?? [];
      setState(() {
        _all = items.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final labels = ['pending', 'accepted', 'playing', 'rejected'];
    return _all.where((r) => r['status'] == labels[_filter]).toList();
  }

  Future<void> _act(String requestId, String action) async {
    HapticFeedback.selectionClick();
    try {
      await ApiService().respondToRequest(requestId, action);
      await _loadQueue();
    } catch (_) {}
  }

  Future<void> _markPlaying(String requestId) async {
    try {
      await ApiService().markPlaying(requestId);
      await _loadQueue();
    } catch (_) {}
  }

  Future<void> _markComplete(String requestId) async {
    try {
      await ApiService().markComplete(requestId);
      await _loadQueue();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final filters = ['Pending', 'Accepted', 'Playing', 'Rejected'];
    return Column(
      children: [
        // Filter strip
        Container(
          height: 44,
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            itemCount: filters.length,
            itemBuilder: (_, i) {
              final sel = _filter == i;
              return GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.warmGradient : null,
                    color: sel
                        ? null
                        : (isDark
                            ? AppColors.bgElevatedDark
                            : AppColors.bgElevatedLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel
                            ? Colors.transparent
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight)),
                  ),
                  child: Text(filters[i],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight))),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.pink))
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎵', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('No ${filters[_filter].toLowerCase()} requests',
                          style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.pink,
                  onRefresh: _loadQueue,
                  child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final reqId = r['requestId'] as String? ?? r['request_id'] as String? ?? '';
                    final song = r['songTitle'] as String? ?? r['song_title'] as String? ?? 'Unknown Song';
                    final artist = r['artist'] as String? ?? '';
                    final requester = r['requesterName'] as String? ?? 'Unknown';
                    final tip = (r['tipAmount'] as num?)?.toInt() ?? 0;
                    final votes = (r['voteCount'] as num?)?.toInt() ?? 0;
                    final status = r['status'] as String? ?? 'pending';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgCardDark : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: status == 'playing'
                                ? AppColors.pink.withOpacity(0.4)
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle),
                            child: const Center(
                                child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedUser,
                                    size: 20,
                                    color: Colors.white)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(artist.isNotEmpty ? '$song - $artist' : song,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight)),
                                Text(
                                    'by $requester  ·  $votes votes',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textMutedDark
                                            : AppColors.textMutedLight)),
                                if (tip > 0)
                                  Row(children: [
                                    const HugeIcon(
                                        icon: HugeIcons.strokeRoundedMoney01,
                                        size: 12,
                                        color: AppColors.cyan),
                                    const SizedBox(width: 3),
                                    Text('KES $tip tip',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cyan)),
                                  ]),
                              ],
                            ),
                          ),
                          if (status == 'pending')
                            Row(children: [
                              _IconBtn(HugeIcons.strokeRoundedPlay,
                                  AppColors.green,
                                  () => _act(reqId, 'accept')),
                              const SizedBox(width: 6),
                              _IconBtn(
                                  HugeIcons.strokeRoundedCancel01,
                                  AppColors.red,
                                  () => _act(reqId, 'reject')),
                            ])
                          else if (status == 'accepted')
                            _IconBtn(HugeIcons.strokeRoundedPlay, AppColors.green,
                                () => _markPlaying(reqId))
                          else if (status == 'playing')
                            _IconBtn(HugeIcons.strokeRoundedStop, AppColors.red,
                                () => _markComplete(reqId))
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status == 'accepted'
                                        ? AppColors.cyan
                                        : AppColors.red)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status == 'accepted'
                                    ? 'Accepted'
                                    : 'Rejected',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'accepted'
                                        ? AppColors.cyan
                                        : AppColors.red),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EARNINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _EarningsTab extends StatefulWidget {
  final bool isDark;
  const _EarningsTab({required this.isDark});

  @override
  State<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<_EarningsTab> {
  int _withdrawMethod = 0; // 0=M-Pesa 1=Bank 2=Airtel
  int? _quickAmount;
  final _accountCtrl = TextEditingController();
  double _balance = 0;
  Map<String, dynamic>? _earningsData;
  List<Map<String, dynamic>> _txHistory = [];

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    try {
      final results = await Future.wait([
        ApiService().getWalletBalance(),
        ApiService().getDJEarnings(),
        ApiService().getTransactionHistory(limit: 10),
      ]);
      final walletData = results[0].data['data'];
      final earningsData = results[1].data['data'];
      final txItems = (results[2].data['data']['items'] as List?) ?? [];
      setState(() {
        _balance = (walletData['balance'] as num?)?.toDouble() ?? 0;
        _earningsData = earningsData as Map<String, dynamic>?;
        _txHistory = txItems.cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final methods = ['M-Pesa', 'Bank', 'Airtel'];
    final totalEarned = (_earningsData?['totalEarned'] as num?)?.toDouble() ?? 0;
    final tipCount = (_earningsData?['tipCount'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                const Text('Wallet Balance', style: TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('KES ${_balance.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('Total Earned: KES ${totalEarned.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('$tipCount tips', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Withdraw panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.bgCardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Withdraw Earnings', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 12),
                // Method
                Row(
                  children: methods.asMap().entries.map((e) {
                    final sel = _withdrawMethod == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _withdrawMethod = e.key),
                        child: Container(
                          margin: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.warmGradient : null,
                            color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                          ),
                          child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Amount quick picks
                Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(height: 8),
                Row(
                  children: [500, 1000, 2000, null].map((a) {
                    final label = a == null ? 'All' : 'KES $a';
                    final sel = _quickAmount == a;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _quickAmount = a),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            gradient: sel ? AppColors.primaryGradient : null,
                            color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                          ),
                          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _accountCtrl,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: _withdrawMethod == 1 ? 'Bank account number' : 'Phone number (07XX...)',
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    filled: true,
                    fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.purple)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('Withdraw Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle('Transaction History', isDark: isDark),
          const SizedBox(height: 10),
          ...(_txHistory.isNotEmpty
            ? _txHistory.map((t) {
                final txType = t['type'] as String? ?? 'debit';
                final isIn = txType == 'credit' || txType == 'tip' || txType == 'topup';
                final label = t['description'] as String? ?? 'Transaction';
                final method = t['method'] as String? ?? 'In-app';
                final time = t['createdAt'] as String? ?? '';
                final amount = t['amount'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: isDark ? AppColors.bgCardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  child: Row(children: [
                    Container(width: 38, height: 38,
                      decoration: BoxDecoration(color: (isIn ? AppColors.cyan : AppColors.red).withOpacity(0.12), shape: BoxShape.circle),
                      child: Center(child: HugeIcon(icon: isIn ? HugeIcons.strokeRoundedArrowDown01 : HugeIcons.strokeRoundedArrowUp01, size: 18, color: isIn ? AppColors.cyan : AppColors.red))),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      Text('$method · $time', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ])),
                    Text('${isIn ? '+' : '-'} KES $amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isIn ? AppColors.cyan : AppColors.red)),
                  ]),
                );
              })
            : [Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No transactions yet', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight))))]
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _StatsTab extends StatefulWidget {
  final bool isDark;
  final dynamic user;
  const _StatsTab({required this.isDark, required this.user});

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, dynamic>? _earningsData;
  List<Map<String, dynamic>> _topTippers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiService().getDJEarnings(),
        ApiService().getTopTippers(limit: 5),
      ]);
      final earnings = results[0].data['data'] as Map<String, dynamic>?;
      final tippers = ((results[1].data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _earningsData = earnings; _topTippers = tippers; });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final totalTips = (_earningsData?['tipCount'] as num?)?.toInt() ?? 34;
    final totalEarned = (_earningsData?['totalEarned'] as num?)?.toDouble() ?? 48000;
    final liveSessions = (_earningsData?['liveSessions'] as num?)?.toInt() ?? 12;
    final requestsHandled = (_earningsData?['requestsHandled'] as num?)?.toInt() ?? 287;
    final earnedK = totalEarned >= 1000 ? 'KES ${(totalEarned / 1000).toStringAsFixed(0)}K' : 'KES ${totalEarned.toStringAsFixed(0)}';

    final weeklySummary = (_earningsData?['weeklySummary'] as List?)?.cast<Map<String, dynamic>>();
    final defaultWeekly = [
      ('This Week', 'KES 12,450', 0.62),
      ('Last Week', 'KES 9,800', 0.49),
      ('2 Weeks Ago', 'KES 11,200', 0.56),
      ('3 Weeks Ago', 'KES 8,400', 0.42),
    ];

    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: _load,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats
          Row(children: [
            _StatCard(label: 'Total Tips', value: '$totalTips', icon: HugeIcons.strokeRoundedFavourite, color: AppColors.pink, isDark: isDark),
            const SizedBox(width: 10),
            _StatCard(label: 'Total Earned', value: earnedK, icon: HugeIcons.strokeRoundedMoney01, color: AppColors.cyan, isDark: isDark),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatCard(label: 'Live Sessions', value: '$liveSessions', icon: HugeIcons.strokeRoundedRadio, color: AppColors.red, isDark: isDark),
            const SizedBox(width: 10),
            _StatCard(label: 'Requests', value: '$requestsHandled', icon: HugeIcons.strokeRoundedMusicNote01, color: AppColors.purple, isDark: isDark),
          ]),

          const SizedBox(height: 20),

          _SectionTitle('Earnings Breakdown', isDark: isDark),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.bgCardDark : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            child: Column(
              children: [
                if (weeklySummary != null && weeklySummary.isNotEmpty)
                  ...weeklySummary.map((w) {
                    final label = w['label'] as String? ?? 'Week';
                    final amount = (w['amount'] as num?)?.toDouble() ?? 0;
                    final max = weeklySummary.map((x) => (x['amount'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);
                    final frac = max > 0 ? amount / max : 0.0;
                    final amtStr = amount >= 1000 ? 'KES ${(amount / 1000).toStringAsFixed(1)}K' : 'KES ${amount.toStringAsFixed(0)}';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                          Text(amtStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: frac.clamp(0.0, 1.0), minHeight: 6, backgroundColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan))),
                      ]),
                    );
                  })
                else
                  ...defaultWeekly.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(e.$1, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        Text(e.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.cyan)),
                      ]),
                      const SizedBox(height: 6),
                      ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: e.$3, minHeight: 6, backgroundColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan))),
                    ]),
                  )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SectionTitle('Top Tippers', isDark: isDark),
          const SizedBox(height: 10),
          ..._topTippers.asMap().entries.map((e) {
            final t = e.value as Map<String, dynamic>;
            final name = t['name'] as String? ?? t['userName'] as String? ?? 'User';
            final amount = t['amount'] ?? t['totalTipped'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: isDark ? AppColors.bgCardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
              child: Row(children: [
                Container(width: 28, height: 28,
                  decoration: BoxDecoration(color: e.key == 0 ? const Color(0xFFFFD700).withOpacity(0.15) : e.key == 1 ? const Color(0xFFC0C0C0).withOpacity(0.15) : e.key == 2 ? const Color(0xFFCD7F32).withOpacity(0.15) : AppColors.bgElevatedDark, shape: BoxShape.circle),
                  child: Center(child: Text(e.key == 0 ? '🥇' : e.key == 1 ? '🥈' : e.key == 2 ? '🥉' : '${e.key + 1}', style: const TextStyle(fontSize: 14)))),
                const SizedBox(width: 10),
                Container(width: 32, height: 32, decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle), child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 16, color: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight))),
                Text('KES $amount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.orange)),
              ]),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  final bool isDark;
  final dynamic user;
  const _SettingsTab({required this.isDark, required this.user});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _rateCtrl;
  List<String> _genres = ['Afrobeats', 'Hip Hop'];
  bool _saving = false;
  bool _loadingProfile = true;

  final _allGenres = ['Afrobeats', 'Hip Hop', 'House', 'R&B', 'Electronic', 'Reggae', 'Dancehall', 'Amapiano'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? 'DJ');
    _bioCtrl = TextEditingController(text: '');
    _rateCtrl = TextEditingController(text: '5000');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await ApiService().getDJProfile();
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() {
          _nameCtrl.text = data['stageName'] as String? ?? widget.user?.name ?? 'DJ';
          _bioCtrl.text = data['bio'] as String? ?? '';
          _rateCtrl.text = '${(data['hourlyRate'] as num?)?.toInt() ?? 5000}';
          final rawGenres = data['genres'];
          if (rawGenres is List) _genres = rawGenres.cast<String>();
          _loadingProfile = false;
        });
      } else {
        if (mounted) setState(() => _loadingProfile = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final djProfileRes = await ApiService().getDJProfile();
      final djData = djProfileRes.data['data'] as Map<String, dynamic>?;
      final djId = djData?['djId'] as String?;
      if (djId != null) {
        await ApiService().dio.put('/dj/profile', data: {
          'stageName': _nameCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'hourlyRate': int.tryParse(_rateCtrl.text.trim()) ?? 5000,
          'genres': _genres,
        });
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✅ Profile updated!'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('DJ Profile', isDark: isDark),
          const SizedBox(height: 12),

          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.warmGradient, boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.35), blurRadius: 16)]),
                  child: const Center(child: Text('🎧', style: TextStyle(fontSize: 38))),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                    child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _SettingField(label: 'Stage Name', ctrl: _nameCtrl, hint: 'Your DJ name', isDark: isDark),
          const SizedBox(height: 14),
          _SettingField(label: 'Bio', ctrl: _bioCtrl, hint: 'Tell fans about yourself...', isDark: isDark, maxLines: 3),
          const SizedBox(height: 14),
          _SettingField(label: 'Hourly Rate (KES)', ctrl: _rateCtrl, hint: '5000', isDark: isDark, keyboardType: TextInputType.number),

          const SizedBox(height: 20),

          _SectionTitle('Genres / Music Style', isDark: isDark),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allGenres.map((g) {
              final sel = _genres.contains(g);
              return GestureDetector(
                onTap: () => setState(() => sel ? _genres.remove(g) : _genres.add(g)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.warmGradient : null,
                    color: sel ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ),
                  child: Text(g, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(gradient: AppColors.warmGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]),
              child: Center(
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _SettingField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final bool isDark;
  final int maxLines;
  final TextInputType? keyboardType;

  const _SettingField({required this.label, required this.ctrl, required this.hint, required this.isDark, this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            filled: true,
            fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.purple, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isDark;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: isDark ? AppColors.bgCardDark : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Center(child: HugeIcon(icon: icon, size: 20, color: color))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(title, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));
}

class _IconBtn extends StatelessWidget {
  final List<List<dynamic>> icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Center(child: HugeIcon(icon: icon, size: 15, color: color)),
    ),
  );
}

// ── Mock Data ──────────────────────────────────────────────────────────────────
class _Req {
  final String song, requester, status, reqId;
  final int tip, votes;
  const _Req({required this.song, required this.requester, required this.tip, required this.votes, required this.status, this.reqId = ''});
}


class _Track {
  final String trackId, title, artist, duration, genre;
  const _Track({this.trackId = '', required this.title, required this.artist, required this.duration, this.genre = ''});
}

