import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class MerchantScreen extends ConsumerStatefulWidget {
  const MerchantScreen({super.key});

  @override
  ConsumerState<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends ConsumerState<MerchantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        title: Row(
          children: [
            const Text('🏛️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              user?.name ?? 'Venue Dashboard',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 17,
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
          indicatorColor: AppColors.purple,
          labelColor: AppColors.purple,
          unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Check-ins'),
            Tab(text: 'DJ Bookings'),
            Tab(text: 'Offers'),
            Tab(text: 'Analytics'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(isDark: isDark),
          _CheckInsTab(isDark: isDark),
          _DJBookingsTab(isDark: isDark),
          _OffersTab(isDark: isDark),
          _AnalyticsTab(isDark: isDark),
          _SettingsTab(isDark: isDark),
        ],
      ),
    );
  }
}

// ─── OVERVIEW TAB ────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  List<Map<String, dynamic>> _venues = [];
  Map<String, dynamic>? _analytics;
  List<dynamic> _checkins = [];
  String? _selectedVenueId;
  String? _selectedVenueName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    try {
      final res = await ApiService().getMerchantVenues();
      final items = (res.data['data']['items'] as List?) ?? [];
      setState(() {
        _venues = items.cast<Map<String, dynamic>>();
        if (_venues.isNotEmpty) {
          _selectedVenueId = _venues[0]['venueId'] as String?;
          _selectedVenueName = _venues[0]['name'] as String?;
        }
        _loading = false;
      });
      if (_selectedVenueId != null) _loadVenueData(_selectedVenueId!);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadVenueData(String venueId) async {
    try {
      final results = await Future.wait([
        ApiService().getVenueAnalytics(venueId),
        ApiService().getMerchantCheckins(venueId, filter: 'today'),
      ]);
      setState(() {
        _analytics = results[0].data['data'] as Map<String, dynamic>?;
        _checkins = (results[1].data['data']['items'] as List?) ?? [];
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final checkinCount = (_analytics?['todayCheckins'] as num?)?.toInt() ?? _checkins.length;
    final capacity = (_analytics?['capacityUtilization'] as num?)?.toInt() ?? 0;
    final revenue = (_analytics?['revenue'] as num?)?.toDouble() ?? 0;
    final requestCount = (_analytics?['songRequests'] as num?)?.toInt() ?? 0;

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async {
        await _loadVenues();
        if (_selectedVenueId != null) await _loadVenueData(_selectedVenueId!);
      },
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue selector if multiple venues
          if (_venues.length > 1) ...[
            DropdownButtonFormField<String>(
              value: _selectedVenueId,
              decoration: InputDecoration(
                labelText: 'Select Venue',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: _venues.map((v) => DropdownMenuItem<String>(
                value: v['venueId'] as String?,
                child: Text(v['name'] as String? ?? 'Venue'),
              )).toList(),
              onChanged: (id) {
                setState(() {
                  _selectedVenueId = id;
                  _selectedVenueName = _venues.firstWhere((v) => v['venueId'] == id, orElse: () => {})['name'] as String?;
                });
                if (id != null) _loadVenueData(id);
              },
            ),
            const SizedBox(height: 12),
          ],

          // Hero banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.cyanGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_loading ? 'Loading...' : 'Tonight at ${_selectedVenueName ?? "Your Venue"}',
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                      const Text('Live & Open 🟢',
                          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('$checkinCount guests checked in tonight',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                const Text('🏛️', style: TextStyle(fontSize: 42)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // KPI grid
          Row(
            children: [
              _KpiCard(label: 'Check-ins', value: '$checkinCount', sub: 'today', icon: HugeIcons.strokeRoundedLocation01, color: AppColors.purple, isDark: isDark),
              const SizedBox(width: 10),
              _KpiCard(label: 'Capacity', value: '$capacity%', sub: 'utilization', icon: HugeIcons.strokeRoundedAnalytics01, color: AppColors.cyan, isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiCard(label: 'Revenue', value: 'KES ${revenue.toStringAsFixed(0)}', sub: 'DJ tips', icon: HugeIcons.strokeRoundedMoney01, color: AppColors.green, isDark: isDark),
              const SizedBox(width: 10),
              _KpiCard(label: 'Requests', value: '$requestCount', sub: 'song requests', icon: HugeIcons.strokeRoundedMusicNote01, color: AppColors.pink, isDark: isDark),
            ],
          ),

          const SizedBox(height: 20),

          _SectionTitle('Top Song Requests', isDark: isDark),
          const SizedBox(height: 10),
          ..._topSongs.asMap().entries.map((e) => _RankRow(
                rank: e.key + 1,
                title: e.value.$1,
                subtitle: e.value.$2,
                count: e.value.$3,
                isDark: isDark,
              )),

          const SizedBox(height: 20),

          _SectionTitle('Recent Check-ins', isDark: isDark),
          const SizedBox(height: 10),
          if (_checkins.isEmpty && !_loading)
            Center(child: Text('No check-ins today', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)))
          else
          ..._checkins.take(5).map((c) {
            final ci = c as Map<String, dynamic>;
            final name = ci['userName'] as String? ?? 'Guest';
            final time = ci['checkInTime'] as String? ?? ci['check_in_time'] as String? ?? '';
            final xp = ci['xpEarned'] as int? ?? 25;
            return _CheckInTile(
              checkin: _MockCheckIn(name: name, timeAgo: _fmtTime(time), xp: '+$xp XP'),
              isDark: isDark,
            );
          }),

          const SizedBox(height: 80),
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
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return ts;
    }
  }
}

// ─── CHECK-INS TAB ────────────────────────────────────────────────────────────
class _CheckInsTab extends StatefulWidget {
  final bool isDark;
  const _CheckInsTab({required this.isDark});

  @override
  State<_CheckInsTab> createState() => _CheckInsTabState();
}

class _CheckInsTabState extends State<_CheckInsTab> with SingleTickerProviderStateMixin {
  late TabController _inner;
  String _range = 'Today';
  final _ranges = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      children: [
        // Date filter
        Container(
          color: isDark ? AppColors.bgDark : Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _ranges.map((r) {
                final sel = r == _range;
                return GestureDetector(
                  onTap: () => setState(() => _range = r),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: sel ? AppColors.primaryGradient : null,
                      color: sel ? null : (isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ),
                    child: Text(r,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Active count bar
        Container(
          color: isDark ? AppColors.bgDark : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('142 currently inside',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            ],
          ),
        ),
        // Inner tabs
        Container(
          color: isDark ? AppColors.bgDark : Colors.white,
          child: TabBar(
            controller: _inner,
            tabs: const [Tab(text: 'Check-ins'), Tab(text: 'Regulars')],
            indicatorColor: AppColors.purple,
            labelColor: AppColors.purple,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              _CheckinListPanel(isDark: isDark, range: _range),
              _RegularsPanel(isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckinListPanel extends StatefulWidget {
  final bool isDark;
  final String range;
  const _CheckinListPanel({required this.isDark, this.range = 'Today'});

  @override
  State<_CheckinListPanel> createState() => _CheckinListPanelState();
}

class _CheckinListPanelState extends State<_CheckinListPanel> {
  List<Map<String, dynamic>> _checkins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Get first venue to load checkins for
      final venueRes = await ApiService().getMerchantVenues();
      final venues = (venueRes.data['data']['items'] as List?) ?? [];
      if (venues.isNotEmpty) {
        final venueId = (venues[0] as Map<String, dynamic>)['venueId'] as String? ?? '';
        final filter = _rangeToFilter(widget.range);
        final res = await ApiService().getMerchantCheckins(venueId, filter: filter);
        final items = (res.data['data']['items'] as List?) ?? [];
        if (mounted) setState(() { _checkins = items.cast<Map<String, dynamic>>(); _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _rangeToFilter(String range) {
    switch (range) {
      case 'This Week': return 'week';
      case 'This Month': return 'month';
      case 'All Time': return 'all';
      default: return 'today';
    }
  }

  @override
  void didUpdateWidget(_CheckinListPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.range != widget.range) _load();
  }

  String _fmtTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ts; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    final items = _checkins;
    if (items.isEmpty) return RefreshIndicator(color: AppColors.purple, onRefresh: _load, child: ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No check-ins yet', style: TextStyle(color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight))))]));
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final ci = items[i] as Map<String, dynamic>;
          final name = ci['userName'] as String? ?? 'Guest';
          final time = ci['checkInTime'] as String? ?? '';
          final xp = (ci['xpEarned'] as num?)?.toInt() ?? 25;
          return _CheckInTile(
            checkin: _MockCheckIn(name: name, timeAgo: time.isNotEmpty ? _fmtTime(time) : 'Just now', xp: '+$xp XP'),
            isDark: widget.isDark, showDetails: true,
          );
        },
      ),
    );
  }
}

class _RegularsPanel extends StatefulWidget {
  final bool isDark;
  const _RegularsPanel({required this.isDark});

  @override
  State<_RegularsPanel> createState() => _RegularsPanelState();
}

class _RegularsPanelState extends State<_RegularsPanel> {
  List<Map<String, dynamic>> _regulars = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final venueRes = await ApiService().getMerchantVenues();
      final venues = (venueRes.data['data']['items'] as List?) ?? [];
      if (venues.isNotEmpty) {
        final venueId = (venues[0] as Map<String, dynamic>)['venueId'] as String? ?? '';
        final res = await ApiService().getGuestFrequency(venueId);
        final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        if (mounted) setState(() { _regulars = items; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    final list = _regulars;
    if (list.isEmpty) return RefreshIndicator(color: AppColors.purple, onRefresh: _load, child: ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No regulars yet', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight))))]));
    final medals = ['🥇', '🥈', '🥉'];
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final r = list[i] as Map<String, dynamic>;
          final name = r['name'] as String? ?? r['userName'] as String? ?? 'Guest';
          final totalVisits = (r['totalVisits'] as num?)?.toInt() ?? 0;
          final streak = (r['streak'] as num?)?.toInt() ?? 0;
          final lastVisit = r['lastVisit'] as String? ?? '';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Text(i < 3 ? medals[i] : '${i + 1}', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 20, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        const SizedBox(width: 6),
                        if (streak >= 4) const Text('🔥', style: TextStyle(fontSize: 13)),
                      ]),
                      Text(
                        lastVisit.isNotEmpty ? 'Last visit: $lastVisit · $totalVisits total' : '$totalVisits visits total',
                        style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ],
                  ),
                ),
                Text('${streak}wk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: streak >= 4 ? AppColors.orange : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── DJ BOOKINGS TAB ─────────────────────────────────────────────────────────
class _DJBookingsTab extends StatefulWidget {
  final bool isDark;
  const _DJBookingsTab({required this.isDark});

  @override
  State<_DJBookingsTab> createState() => _DJBookingsTabState();
}

class _DJBookingsTabState extends State<_DJBookingsTab> with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      children: [
        Container(
          color: isDark ? AppColors.bgDark : Colors.white,
          child: TabBar(
            controller: _inner,
            tabs: const [Tab(text: 'DJ Line-up'), Tab(text: 'Requests')],
            indicatorColor: AppColors.purple,
            labelColor: AppColors.purple,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              _DJLineupPanel(isDark: isDark),
              _DJRequestsPanel(isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

class _DJLineupPanel extends StatelessWidget {
  final bool isDark;
  const _DJLineupPanel({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Live now banner
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text('● LIVE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DJ Marcus K', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Playing: Afrobeats Mix Vol. 3 · KES 500 tip', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text('No DJ bookings scheduled', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13)),
      ],
    );
  }
}

class _DJCard extends StatelessWidget {
  final _MockDJ dj;
  final bool isDark;
  const _DJCard({required this.dj, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dj.isLive ? AppColors.purple.withOpacity(0.4) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(dj.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(dj.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    const SizedBox(width: 6),
                    if (dj.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red)),
                      ),
                  ],
                ),
                Text('${dj.genre} · ${dj.timeSlot}',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(dj.status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(dj.status,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(dj.status))),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    if (s == 'Live') return AppColors.red;
    if (s == 'Confirmed') return AppColors.green;
    return AppColors.orange;
  }
}

class _DJRequestsPanel extends StatefulWidget {
  final bool isDark;
  const _DJRequestsPanel({required this.isDark});

  @override
  State<_DJRequestsPanel> createState() => _DJRequestsPanelState();
}

class _DJRequestsPanelState extends State<_DJRequestsPanel> {
  List<_MockRequest> _requests = [];
  bool _loading = false;

  Future<void> _act(int i, String action) async {
    final reqId = (_requests[i] as dynamic).requestId as String? ?? '';
    setState(() => _requests[i] = _MockRequest(
      song: _requests[i].song,
      artist: _requests[i].artist,
      requester: _requests[i].requester,
      tip: _requests[i].tip,
      votes: _requests[i].votes,
      status: action,
    ));
    if (reqId.isNotEmpty) {
      try {
        await ApiService().respondToRequest(reqId, action);
      } catch (_) {
        // revert on fail
        setState(() => _requests[i] = _MockRequest(
          song: _requests[i].song, artist: _requests[i].artist,
          requester: _requests[i].requester, tip: _requests[i].tip,
          votes: _requests[i].votes, status: 'pending',
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _requests.length,
      itemBuilder: (_, i) {
        final r = _requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.song, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                        Text('${r.artist} · by ${r.requester}', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('KES ${r.tip}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
                      Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedThumbsUp, size: 13, color: AppColors.purple),
                          const SizedBox(width: 3),
                          Text('${r.votes}', style: const TextStyle(fontSize: 11, color: AppColors.purple)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (r.status == 'pending') ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _act(i, 'accepted').ignore(),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _act(i, 'declined').ignore(),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.red.withOpacity(0.3)),
                          ),
                          child: const Center(child: Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red))),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (r.status == 'accepted' ? AppColors.green : AppColors.red).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(r.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: r.status == 'accepted' ? AppColors.green : AppColors.red)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── OFFERS TAB ──────────────────────────────────────────────────────────────
class _OffersTab extends StatefulWidget {
  final bool isDark;
  const _OffersTab({required this.isDark});

  @override
  State<_OffersTab> createState() => _OffersTabState();
}

class _OffersTabState extends State<_OffersTab> {
  List<_MockOffer> _offers = [];
  String? _venueId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    setState(() => _loading = true);
    try {
      final venueRes = await ApiService().getMerchantVenues();
      final venues = (venueRes.data['data']['items'] as List?) ?? [];
      if (venues.isNotEmpty) {
        _venueId = (venues[0] as Map<String, dynamic>)['venueId'] as String? ?? '';
        final res = await ApiService().getVenueOffers(_venueId!);
        final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        if (mounted) setState(() {
          _offers = items.map((o) => _MockOffer(
            offerId: o['offerId'] as String? ?? o['_id'] as String? ?? '',
            title: o['title'] as String? ?? '',
            description: o['description'] as String? ?? '',
            type: o['type'] as String? ?? 'discount',
            validUntil: o['validUntil'] as String? ?? '',
            maxClaims: (o['maxClaims'] as num?)?.toInt() ?? 0,
            claims: (o['claims'] as num?)?.toInt() ?? 0,
            isActive: o['isActive'] as bool? ?? true,
          )).toList();
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleOffer(int i) async {
    final offer = _offers[i];
    final newActive = !offer.isActive;
    setState(() => _offers[i] = _MockOffer(
      offerId: offer.offerId, title: offer.title, description: offer.description,
      type: offer.type, validUntil: offer.validUntil, maxClaims: offer.maxClaims,
      claims: offer.claims, isActive: newActive,
    ));
    if (_venueId != null && offer.offerId.isNotEmpty) {
      try {
        await ApiService().updateVenueOffer(_venueId!, offer.offerId, {'isActive': newActive});
      } catch (_) {
        setState(() => _offers[i] = _MockOffer(
          offerId: offer.offerId, title: offer.title, description: offer.description,
          type: offer.type, validUntil: offer.validUntil, maxClaims: offer.maxClaims,
          claims: offer.claims, isActive: offer.isActive,
        ));
      }
    }
  }

  Future<void> _deleteOffer(int i) async {
    final offer = _offers[i];
    setState(() => _offers.removeAt(i));
    if (_venueId != null && offer.offerId.isNotEmpty) {
      try {
        await ApiService().deleteVenueOffer(_venueId!, offer.offerId);
      } catch (_) {
        setState(() => _offers.insert(i, offer));
      }
    }
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateOfferSheet(isDark: widget.isDark, onCreated: (o) async {
        setState(() => _offers.insert(0, o));
        if (_venueId != null) {
          try {
            final res = await ApiService().createVenueOffer(_venueId!, {
              'title': o.title,
              'description': o.description,
              'type': o.type,
              'validUntil': o.validUntil,
              'maxClaims': o.maxClaims,
              'isActive': true,
            });
            final created = res.data['data'] as Map<String, dynamic>?;
            if (created != null) {
              final newOffer = _MockOffer(
                offerId: created['offerId'] as String? ?? created['_id'] as String? ?? '',
                title: o.title, description: o.description, type: o.type,
                validUntil: o.validUntil, maxClaims: o.maxClaims, claims: 0, isActive: true,
              );
              if (mounted) setState(() => _offers[0] = newOffer);
            }
          } catch (_) {}
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _loadOffers,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Text('${_offers.where((o) => o.isActive).length} Active Offers',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const Spacer(),
              GestureDetector(
                onTap: _showCreateSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('New Offer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _offers.length,
            itemBuilder: (_, i) => _OfferCard(
              offer: _offers[i],
              isDark: isDark,
              onToggle: () => _toggleOffer(i).ignore(),
              onDelete: () => _deleteOffer(i).ignore(),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _MockOffer offer;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _OfferCard({required this.offer, required this.isDark, required this.onToggle, required this.onDelete});

  Color get _typeColor {
    if (offer.type == 'drink') return AppColors.cyan;
    if (offer.type == 'table') return AppColors.purple;
    return AppColors.orange;
  }

  String get _typeLabel {
    if (offer.type == 'drink') return '🍸 Drink';
    if (offer.type == 'table') return '🪑 Table';
    return '💎 VIP';
  }

  @override
  Widget build(BuildContext context) {
    final progress = offer.maxClaims > 0 ? offer.claims / offer.maxClaims : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(_typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor)),
              ),
              const Spacer(),
              Switch(
                value: offer.isActive,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.purple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              GestureDetector(
                onTap: onDelete,
                child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 18, color: AppColors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(offer.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 3),
          Text(offer.description, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          const SizedBox(height: 8),
          Row(
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(width: 4),
              Text('Valid until ${offer.validUntil}',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              const Spacer(),
              Text('${offer.claims}/${offer.maxClaims} claimed',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(_typeColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateOfferSheet extends StatefulWidget {
  final bool isDark;
  final Function(_MockOffer) onCreated;
  const _CreateOfferSheet({required this.isDark, required this.onCreated});

  @override
  State<_CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<_CreateOfferSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'drink';
  String _validUntil = '12:00 AM';
  int _maxClaims = 50;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bot = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(16, 20, 16, bot + 16),
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
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 14),
          Text('New Offer', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 14),
          _SheetField(ctrl: _titleCtrl, label: 'Offer Title', hint: 'e.g. Free Shot on Entry', isDark: isDark),
          const SizedBox(height: 10),
          _SheetField(ctrl: _descCtrl, label: 'Description', hint: 'What guests get...', isDark: isDark, maxLines: 2),
          const SizedBox(height: 10),
          Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          const SizedBox(height: 6),
          Row(
            children: ['drink', 'table', 'vip'].map((t) {
              final sel = t == _type;
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: sel ? AppColors.primaryGradient : null,
                    color: sel ? null : (isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                  ),
                  child: Text(t[0].toUpperCase() + t.substring(1),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight))),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (_titleCtrl.text.trim().isEmpty) return;
              widget.onCreated(_MockOffer(
                title: _titleCtrl.text.trim(),
                description: _descCtrl.text.trim().isEmpty ? 'Special offer tonight!' : _descCtrl.text.trim(),
                type: _type,
                validUntil: _validUntil,
                maxClaims: _maxClaims,
                claims: 0,
                isActive: true,
              ));
              Navigator.pop(context);
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('Create Offer', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool isDark;
  final int maxLines;
  const _SheetField({required this.ctrl, required this.label, required this.hint, required this.isDark, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ANALYTICS TAB ───────────────────────────────────────────────────────────
class _AnalyticsTab extends StatefulWidget {
  final bool isDark;
  const _AnalyticsTab({required this.isDark});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  String? _venueId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final venueRes = await ApiService().getMerchantVenues();
      final venues = (venueRes.data['data']['items'] as List?) ?? [];
      if (venues.isNotEmpty) {
        final id = (venues[0] as Map<String, dynamic>)['venueId'] as String? ?? '';
        _venueId = id;
        final res = await ApiService().getVenueAnalytics(id);
        if (mounted) setState(() { _analytics = res.data['data'] as Map<String, dynamic>?; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final totalCheckins = (_analytics?['totalCheckins'] as num?)?.toInt() ?? 1284;
    final revenue = (_analytics?['revenue'] as num?)?.toDouble() ?? 284000;
    final uniqueVisitors = (_analytics?['uniqueVisitors'] as num?)?.toInt() ?? 842;
    final capacityAvg = (_analytics?['capacityUtilization'] as num?)?.toInt() ?? 67;
    final todayCheckins = (_analytics?['todayCheckins'] as num?)?.toInt() ?? 142;
    final songRequests = (_analytics?['songRequests'] as num?)?.toInt() ?? 38;
    final peakHour = _analytics?['peakHour'] as String? ?? '11 PM – 1 AM';
    final revenueK = revenue >= 1000 ? 'KES ${(revenue / 1000).toStringAsFixed(0)}K' : 'KES ${revenue.toStringAsFixed(0)}';

    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: _load,
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator(color: AppColors.purple))),
          if (!_loading) ...[
          // KPI grid
          Row(
            children: [
              _KpiCard(label: 'Total Check-ins', value: '$totalCheckins', sub: 'this month', icon: HugeIcons.strokeRoundedLocation01, color: AppColors.purple, isDark: isDark),
              const SizedBox(width: 10),
              _KpiCard(label: 'Revenue', value: revenueK, sub: 'this month', icon: HugeIcons.strokeRoundedMoney01, color: AppColors.green, isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _KpiCard(label: 'Unique Visitors', value: '$uniqueVisitors', sub: 'this month', icon: HugeIcons.strokeRoundedUserGroup, color: AppColors.cyan, isDark: isDark),
              const SizedBox(width: 10),
              _KpiCard(label: 'Capacity Avg', value: '$capacityAvg%', sub: 'utilization', icon: HugeIcons.strokeRoundedAnalytics01, color: AppColors.orange, isDark: isDark),
            ],
          ),

          const SizedBox(height: 20),
          _SectionTitle('Venue Stats', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                _StatRow("Today's Check-ins", '$todayCheckins', isDark: isDark),
                _StatRow('Avg Stay Duration', _analytics?['avgStayDuration'] as String? ?? '2h 34m', isDark: isDark),
                _StatRow('Peak Hour', peakHour, isDark: isDark),
                _StatRow('Song Requests', '$songRequests', isDark: isDark, last: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionTitle('Top 5 Requested Songs', isDark: isDark),
          const SizedBox(height: 10),
          ..._topSongs.asMap().entries.map((e) => _BarRow(
                label: e.value.$1,
                sub: e.value.$2,
                count: e.value.$3,
                maxCount: _topSongs.map((s) => s.$3).reduce((a, b) => a > b ? a : b),
                isDark: isDark,
              )),
          ],

          const SizedBox(height: 80),
        ],
      ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool last;
  const _StatRow(this.label, this.value, {required this.isDark, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ],
          ),
        ),
        if (!last) Divider(height: 0.5, color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final String sub;
  final int count;
  final int maxCount;
  final bool isDark;
  const _BarRow({required this.label, required this.sub, required this.count, required this.maxCount, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    Text(sub, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                  ],
                ),
              ),
              Text('$count requests', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: count / maxCount,
              minHeight: 5,
              backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SETTINGS TAB ────────────────────────────────────────────────────────────
class _SettingsTab extends StatefulWidget {
  final bool isDark;
  const _SettingsTab({required this.isDark});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final _nameCtrl = TextEditingController(text: 'Club Insomnia');
  final _phoneCtrl = TextEditingController(text: '+254 700 000 000');
  final _addressCtrl = TextEditingController(text: 'Westlands, Nairobi');
  final _capacityCtrl = TextEditingController(text: '200');
  bool _saving = false;
  bool _toggling = false;
  String? _venueId;
  String _venueStatus = 'active';

  final List<String> _photos = ['🎉', '🎵', '🏛️', '🔥'];
  final List<_MockDJSlot> _djSlots = [
    _MockDJSlot(name: 'DJ Marcus K', slot: '10 PM – 12 AM'),
    _MockDJSlot(name: 'DJ Aura', slot: '12 AM – 2 AM'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadVenueId();
  }

  Future<void> _loadVenueId() async {
    try {
      final res = await ApiService().getMerchantVenues();
      final venues = (res.data['data']['items'] as List?) ?? [];
      if (venues.isNotEmpty && mounted) {
        final v = (venues[0] as Map<String, dynamic>);
        setState(() {
          _venueId = v['venueId'] as String?;
          if (v['name'] != null) _nameCtrl.text = v['name'] as String;
          if (v['phone'] != null) _phoneCtrl.text = v['phone'] as String;
          if (v['address'] != null) _addressCtrl.text = v['address'] as String;
          if (v['capacity'] != null) _capacityCtrl.text = '${v['capacity']}';
          if (v['status'] != null) _venueStatus = v['status'] as String;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleStatus() async {
    if (_venueId == null) return;
    setState(() => _toggling = true);
    HapticFeedback.lightImpact();
    try {
      final res = await ApiService().toggleVenueStatus(_venueId!);
      final data = res.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        setState(() => _venueStatus = data['status'] as String? ?? _venueStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    if (mounted) setState(() => _toggling = false);
  }

  Future<void> _save() async {
    if (_venueId == null) return;
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      await ApiService().updateVenue(_venueId!, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        if (_capacityCtrl.text.isNotEmpty) 'capacity': int.tryParse(_capacityCtrl.text.trim()),
      });
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Venue settings saved!'),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
          // ── Venue On/Off Toggle ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _venueStatus == 'active'
                        ? AppColors.green.withOpacity(0.15)
                        : AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPowerSocket01,
                    size: 20,
                    color: _venueStatus == 'active' ? AppColors.green : AppColors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Venue Status',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        )),
                      const SizedBox(height: 2),
                      Text(
                        _venueStatus == 'active'
                            ? 'Open — visible to party goers'
                            : _venueStatus == 'inactive'
                                ? 'Closed — hidden from discovery'
                                : 'Status: $_venueStatus',
                        style: TextStyle(
                          fontSize: 11,
                          color: _venueStatus == 'active' ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_venueStatus == 'suspended')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Suspended', style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                  )
                else
                  GestureDetector(
                    onTap: _toggling ? null : _toggleStatus,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 26,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _venueStatus == 'active' ? AppColors.green : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                      child: _toggling
                          ? Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white)))
                          : AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _venueStatus == 'active' ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionTitle('Venue Photos', isDark: isDark),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ..._photos.map((e) => Container(
                  width: 76,
                  height: 76,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 30))),
                )),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, style: BorderStyle.solid),
                    ),
                    child: Center(
                      child: HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 24, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionTitle('Basic Info', isDark: isDark),
          const SizedBox(height: 10),
          _SettingField(ctrl: _nameCtrl, label: 'Venue Name', isDark: isDark),
          const SizedBox(height: 10),
          _SettingField(ctrl: _phoneCtrl, label: 'Phone', isDark: isDark),
          const SizedBox(height: 10),
          _SettingField(ctrl: _addressCtrl, label: 'Address', isDark: isDark),
          const SizedBox(height: 10),
          _SettingField(ctrl: _capacityCtrl, label: 'Capacity', isDark: isDark, keyboardType: TextInputType.number),

          const SizedBox(height: 20),
          _SectionTitle('Venue Details', isDark: isDark),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              children: [
                _StatRow('Category', 'Night Club', isDark: isDark),
                _StatRow('Area', 'Westlands, Nairobi', isDark: isDark),
                _StatRow('Status', '🟢 Active', isDark: isDark),
                _StatRow('Active Users', '142', isDark: isDark, last: true),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionTitle('DJ Line-up', isDark: isDark),
          const SizedBox(height: 10),
          ..._djSlots.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 18, color: AppColors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      Text(e.value.slot, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _djSlots.removeAt(e.key)),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete01, size: 18, color: AppColors.red),
                ),
              ],
            ),
          )),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.purple.withOpacity(0.3)),
              ),
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.purple),
                    SizedBox(width: 6),
                    Text('Add DJ Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.purple)),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 50,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool isDark;
  final TextInputType keyboardType;
  const _SettingField({required this.ctrl, required this.label, required this.isDark, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SHARED WIDGETS ───────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final List<List<dynamic>> icon;
  final Color color;
  final bool isDark;

  const _KpiCard({
    required this.label, required this.value, required this.sub,
    required this.icon, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: HugeIcon(icon: icon, size: 18, color: color)),
                ),
                const Spacer(),
                Text(sub, style: TextStyle(fontSize: 10, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final int count;
  final bool isDark;
  const _RankRow({required this.rank, required this.title, required this.subtitle, required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text(rank <= 3 ? medals[rank - 1] : '$rank', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text('$count req', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle(this.title, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight));
  }
}

class _CheckInTile extends StatelessWidget {
  final _MockCheckIn checkin;
  final bool isDark;
  final bool showDetails;
  const _CheckInTile({required this.checkin, required this.isDark, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checkin.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                Text(showDetails ? '${checkin.timeAgo} · ${checkin.visits} visits' : checkin.timeAgo,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(checkin.xp, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
          ),
        ],
      ),
    );
  }
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
class _MockCheckIn {
  final String name, timeAgo, xp;
  final int visits;
  const _MockCheckIn({required this.name, required this.timeAgo, required this.xp, this.visits = 1});
}

class _MockRegular {
  final String name, lastVisit;
  final int totalVisits, streak;
  final List<double> weekly;
  const _MockRegular({required this.name, required this.lastVisit, required this.totalVisits, required this.streak, required this.weekly});
}

class _MockDJ {
  final String name, emoji, genre, timeSlot, status;
  final bool isLive;
  const _MockDJ({required this.name, required this.emoji, required this.genre, required this.timeSlot, required this.status, this.isLive = false});
}

class _MockRequest {
  final String song, artist, requester, status;
  final int tip, votes;
  const _MockRequest({required this.song, required this.artist, required this.requester, required this.tip, required this.votes, required this.status});
}

class _MockOffer {
  final String offerId, title, description, type, validUntil;
  final int maxClaims, claims;
  final bool isActive;
  const _MockOffer({this.offerId = '', required this.title, required this.description, required this.type, required this.validUntil, required this.maxClaims, required this.claims, required this.isActive});
}

class _MockDJSlot {
  final String name, slot;
  _MockDJSlot({required this.name, required this.slot});
}


const _topSongs = [
  ('Essence', 'Wizkid', 23),
  ('Love Nwantiti', 'CKay', 18),
  ('Overloading', 'Burna Boy', 15),
  ('Midnight', 'Bien', 11),
  ('Sawa Sawa', 'Arrow Bwoy', 9),
];
