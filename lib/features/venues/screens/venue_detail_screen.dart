import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/widgets/gradient_button.dart';

class VenueDetailScreen extends StatefulWidget {
  final String venueId;
  const VenueDetailScreen({super.key, required this.venueId});

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _checkedIn = false;
  bool _checkingIn = false;
  bool _isSaved = false;
  Map<String, dynamic>? _venueData;
  bool _loadingVenue = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVenue();
    _loadCheckinStatus();
  }

  Future<void> _loadVenue() async {
    setState(() => _loadingVenue = true);
    try {
      final res = await ApiService().getVenue(widget.venueId);
      if (mounted) setState(() { _venueData = res.data['data']; _loadingVenue = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingVenue = false);
    }
  }

  Future<void> _loadCheckinStatus() async {
    try {
      final res = await ApiService().getCheckinStatus();
      final data = res.data['data'];
      if (mounted && data != null) {
        setState(() => _checkedIn = data['venueId'] == widget.venueId);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    HapticFeedback.mediumImpact();
    setState(() => _checkingIn = true);
    try {
      if (_checkedIn) {
        await ApiService().checkOut(widget.venueId);
        if (!mounted) return;
        setState(() { _checkingIn = false; _checkedIn = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Checked out. See you next time!'),
          backgroundColor: AppColors.textMutedDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        final res = await ApiService().checkIn(widget.venueId, method: 'app');
        if (!mounted) return;
        final xp = (res.data['data']?['xpEarned'] as num?)?.toInt() ?? 50;
        setState(() { _checkingIn = false; _checkedIn = true; });
        _showCheckInModal(xp);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _checkingIn = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showCheckInModal(int xp) {
    final venueName = _venueData?['name'] as String? ?? 'this venue';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('Checked In!', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('You\'re at $venueName', style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('+$xp XP earned', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        // TODO: open post composer pre-filled with check-in
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Post to Feed', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: isDark ? AppColors.bgDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _isSaved = !_isSaved),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: _isSaved ? HugeIcons.strokeRoundedBookmark02 : HugeIcons.strokeRoundedBookmark01,
                    size: 18,
                    color: _isSaved ? AppColors.purple : Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 18, color: Colors.white),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(builder: (_) {
                    final media = _venueData?['media'] as List?;
                    final url = media != null && media.isNotEmpty
                        ? (media[0] is String ? media[0] as String : (media[0] as Map?)?['url'] as String?)
                        : null;
                    if (url != null && url.isNotEmpty) {
                      return Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                              child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 90)))));
                    }
                    return Container(
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                      child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 90))),
                    );
                  }),
                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            (isDark ? AppColors.bgDark : Colors.white).withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Live badge
                  Positioned(
                    top: 80,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 6),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue name + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _venueData?['name'] as String? ?? 'Venue',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 13, color: AppColors.purple),
                                const SizedBox(width: 3),
                                Flexible(child: Text(
                                  [_venueData?['area'], _venueData?['address']].whereType<String>().join(', '),
                                  style: const TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            const Text('Open', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  // Rating row
                  Builder(builder: (_) {
                    final rating = (_venueData?['rating'] as num?)?.toDouble() ?? 0;
                    final reviewCount = (_venueData?['reviewCount'] as num?)?.toInt() ?? 0;
                    if (rating == 0) return const SizedBox.shrink();
                    return Row(
                      children: [
                        ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 14,
                            color: i < rating.round() ? AppColors.orange : Colors.grey.withOpacity(0.3))),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.orange)),
                        Text(' ($reviewCount reviews)',
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _StatBox(
                        value: '${(_venueData?['activeUsersCount'] as num?)?.toInt() ?? 0}',
                        label: 'Inside', icon: HugeIcons.strokeRoundedUserGroup, isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        value: '${(_venueData?['capacity'] as num?)?.toInt() ?? 0}',
                        label: 'Capacity', icon: HugeIcons.strokeRoundedUserGroup, isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _StatBox(
                        value: _venueData?['category'] as String? ?? '—',
                        label: 'Type', icon: HugeIcons.strokeRoundedMusicNote01, isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Check in / Chat buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GradientButton(
                          label: _checkedIn ? 'Check Out' : 'Check In',
                          icon: HugeIcon(
                            icon: _checkedIn ? HugeIcons.strokeRoundedLogout01 : HugeIcons.strokeRoundedLogin01,
                            color: Colors.white,
                            size: 18,
                          ),
                          gradient: _checkedIn ? AppColors.warmGradient : AppColors.primaryGradient,
                          isLoading: _checkingIn,
                          onTap: _handleCheckIn,
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () => context.push('/chat/venue_insomnia'),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedMessage01,
                                size: 20,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.purple,
                      unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'DJ Lineup'),
                        Tab(text: 'Offers'),
                        Tab(text: 'DJ Room'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Tab content
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AboutTab(isDark: isDark, venueData: _venueData),
                  _DJLineupTab(isDark: isDark, venueData: _venueData),
                  _OffersTab(isDark: isDark, venueData: _venueData),
                  _DJRoomTab(isDark: isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── About Tab ─────────────────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic>? venueData;
  const _AboutTab({required this.isDark, this.venueData});

  @override
  Widget build(BuildContext context) {
    final hours = venueData?['operatingHours'] as Map?;
    final open = hours?['open'] as String?;
    final close = hours?['close'] as String?;
    final hoursStr = (open != null && close != null) ? '$open – $close' : null;
    final address = venueData?['address'] as String?;
    final phone = venueData?['phone'] as String?;
    final deal = venueData?['deal'] as String?;
    final tags = (venueData?['tags'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        if (venueData?['description'] != null)
          Text(
            venueData!['description'] as String,
            style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),

        const SizedBox(height: 20),

        if (hoursStr != null) ...[
          _InfoRow(icon: HugeIcons.strokeRoundedTime01, label: 'Hours', value: hoursStr, isDark: isDark),
          const SizedBox(height: 12),
        ],
        if (address != null) ...[
          _InfoRow(icon: HugeIcons.strokeRoundedLocation01, label: 'Address', value: address, isDark: isDark),
          const SizedBox(height: 12),
        ],
        if (phone != null) ...[
          _InfoRow(icon: HugeIcons.strokeRoundedSmartPhone01, label: 'Contact', value: phone, isDark: isDark),
          const SizedBox(height: 12),
        ],
        if (deal != null) ...[
          _InfoRow(icon: HugeIcons.strokeRoundedMoney01, label: 'Tonight\'s Deal', value: deal, isDark: isDark),
          const SizedBox(height: 12),
        ],

        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Vibe Tags',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.purple.withOpacity(0.25)),
              ),
              child: Text(tag, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.purple)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.icon, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(icon: icon, size: 16, color: AppColors.purple),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── DJ Lineup Tab ─────────────────────────────────────────────────────────────
class _DJLineupTab extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic>? venueData;
  const _DJLineupTab({required this.isDark, this.venueData});

  @override
  Widget build(BuildContext context) {
    // Build DJ list from venue data (dj field or liveDJs list)
    final djs = <Map<String, dynamic>>[];
    final djField = venueData?['dj'];
    if (djField is Map) {
      djs.add(Map<String, dynamic>.from(djField)..['isLive'] = true);
    } else if (djField is List) {
      for (final d in djField) {
        if (d is Map) djs.add(Map<String, dynamic>.from(d));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tonight\'s Lineup',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        if (djs.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No DJ lineup scheduled', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ))
        else
          ...djs.map((dj) => _DJCardData(dj: dj, isDark: isDark)),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _DJCardData extends StatelessWidget {
  final Map<String, dynamic> dj;
  final bool isDark;
  const _DJCardData({required this.dj, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = dj['name'] as String? ?? 'DJ';
    final genre = dj['genre'] as String? ?? '';
    final isLive = dj['isLive'] as bool? ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLive ? AppColors.pink.withOpacity(0.4) : (isDark ? AppColors.borderDark : AppColors.borderLight)),
        boxShadow: isLive ? [BoxShadow(color: AppColors.pink.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(gradient: isLive ? AppColors.warmGradient : AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  if (isLive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(4)),
                      child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                if (genre.isNotEmpty)
                  Text(genre, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ],
            ),
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dj.isLive
              ? AppColors.pink.withOpacity(0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        boxShadow: dj.isLive
            ? [BoxShadow(color: AppColors.pink.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: dj.isLive ? AppColors.warmGradient : AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('🎧', style: TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dj.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    if (dj.isLive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dj.genre,
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                Text(
                  dj.time,
                  style: const TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.orange),
                  Text(' ${dj.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${dj.tips} tips',
                style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Offers Tab ────────────────────────────────────────────────────────────────
class _OffersTab extends StatelessWidget {
  final bool isDark;
  final Map<String, dynamic>? venueData;
  const _OffersTab({required this.isDark, this.venueData});

  @override
  Widget build(BuildContext context) {
    final deal = venueData?['deal'] as String?;
    final offers = (venueData?['offers'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tonight\'s Offers',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        if (deal != null) Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Text(deal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
            ],
          ),
        ),
        if (offers.isEmpty && deal == null)
          Center(child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text('No offers right now', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ))
        else
          ...offers.map((o) => _OfferCard(offer: _MockOffer(
            title: o['title'] as String? ?? '',
            description: o['description'] as String? ?? '',
            validity: o['validity'] as String? ?? '',
            price: o['price'] as String? ?? '',
            emoji: o['emoji'] as String? ?? '🎁',
            isFeatured: o['isFeatured'] as bool? ?? false,
          ), isDark: isDark)),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final _MockOffer offer;
  final bool isDark;
  const _OfferCard({required this.offer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: offer.isFeatured ? AppColors.primaryGradient : null,
        color: offer.isFeatured ? null : (isDark ? AppColors.bgCardDark : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: offer.isFeatured ? null : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Text(offer.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: offer.isFeatured ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  offer.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: offer.isFeatured ? Colors.white70 : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offer.validity,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: offer.isFeatured ? Colors.white60 : AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: offer.isFeatured ? Colors.white.withOpacity(0.2) : AppColors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              offer.price,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: offer.isFeatured ? Colors.white : AppColors.purple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── DJ Room Tab ───────────────────────────────────────────────────────────────
class _DJRoomTab extends StatefulWidget {
  final bool isDark;
  const _DJRoomTab({required this.isDark});

  @override
  State<_DJRoomTab> createState() => _DJRoomTabState();
}

class _DJRoomTabState extends State<_DJRoomTab> {
  final _reqCtrl = TextEditingController();
  int? _selectedTip;
  bool _submitting = false;

  @override
  void dispose() {
    _reqCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_reqCtrl.text.trim().isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _reqCtrl.clear();
      _selectedTip = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('🎵 Song request sent to the DJ!'),
        backgroundColor: AppColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 4, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Now playing
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 5))],
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(child: Text('🎵', style: TextStyle(fontSize: 26))),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Now Playing', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                          Text('Essence - Wizkid ft. Tems', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('DJ Marcus K', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: const Text('🔴 LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.45,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1:54', style: TextStyle(fontSize: 11, color: Colors.white70)),
                    Text('4:12', style: TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Song request
          Text(
            'Request a Song',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _reqCtrl,
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  decoration: InputDecoration(
                    hintText: 'Artist name or song title...',
                    hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    prefixIcon: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.purple),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                ),

                const SizedBox(height: 12),

                Text(
                  'Attach a Tip (optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [50, 100, 200, 500].map((amount) {
                    final selected = _selectedTip == amount;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTip = selected ? null : amount),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: selected ? AppColors.warmGradient : null,
                            color: selected ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? Colors.transparent : (isDark ? AppColors.borderDark : AppColors.borderLight),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text('KES', style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                              Text(
                                '$amount',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _submitting ? null : _submitRequest,
                  child: Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 18, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Send Request', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Request queue
          Text(
            'Recent Requests',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 10),
          ..._djRoomRequests.map((r) => _RoomRequestTile(req: r, isDark: isDark)),
        ],
      ),
    );
  }
}

class _RoomRequestTile extends StatefulWidget {
  final _RoomRequest req;
  final bool isDark;
  const _RoomRequestTile({required this.req, required this.isDark});

  @override
  State<_RoomRequestTile> createState() => _RoomRequestTileState();
}

class _RoomRequestTileState extends State<_RoomRequestTile> {
  bool _voted = false;
  late int _votes;

  @override
  void initState() {
    super.initState();
    _votes = widget.req.votes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.bgCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.req.song,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'by ${widget.req.requester}',
                  style: TextStyle(fontSize: 11, color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                ),
                if (widget.req.tip > 0)
                  Text('KES ${widget.req.tip} tip', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.cyan)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _voted = !_voted;
                _votes += _voted ? 1 : -1;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _voted ? AppColors.purple.withOpacity(0.12) : (widget.isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _voted ? AppColors.purple.withOpacity(0.3) : (widget.isDark ? AppColors.borderDark : AppColors.borderLight)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedThumbsUp,
                    size: 14,
                    color: _voted ? AppColors.purple : (widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$_votes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _voted ? AppColors.purple : (widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomRequest {
  final String song, requester;
  final int votes, tip;
  const _RoomRequest({required this.song, required this.requester, required this.votes, required this.tip});
}

const _djRoomRequests = [
  _RoomRequest(song: 'Mnazi - Mejja', requester: 'sarah.nightout', votes: 24, tip: 200),
  _RoomRequest(song: 'Stamina - Diamond', requester: 'alex_parties', votes: 18, tip: 0),
  _RoomRequest(song: 'Buga - Kizz Daniel', requester: 'nairobi_nights', votes: 31, tip: 500),
  _RoomRequest(song: 'Love Nwantiti - CKay', requester: 'partygoer_ke', votes: 12, tip: 100),
];

// ── Shared StatBox ────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final List<List<dynamic>> icon;
  final bool isDark;

  const _StatBox({required this.value, required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            HugeIcon(icon: icon, color: AppColors.purple, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.purple)),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
          ],
        ),
      ),
    );
  }
}

// ── Mock Data ─────────────────────────────────────────────────────────────────
class _MockDJ {
  final String name, genre, time, rating, tips;
  final bool isLive;
  const _MockDJ({required this.name, required this.genre, required this.time, required this.rating, required this.tips, required this.isLive});
}

const _mockDJs = [
  _MockDJ(name: 'DJ Marcus K', genre: 'Afrobeats · Hip Hop', time: '10PM – 12AM', rating: '4.9', tips: '34', isLive: true),
  _MockDJ(name: 'DJ Flex', genre: 'House · Electronic', time: '12AM – 2AM', rating: '4.7', tips: '21', isLive: false),
  _MockDJ(name: 'DJ Spice', genre: 'R&B · Reggae', time: '2AM – 4AM', rating: '4.8', tips: '18', isLive: false),
];

class _MockOffer {
  final String title, description, validity, price, emoji;
  final bool isFeatured;
  const _MockOffer({required this.title, required this.description, required this.validity, required this.price, required this.emoji, required this.isFeatured});
}

const _mockOffers = [
  _MockOffer(title: 'Ladies Night Special', description: 'Free entry + 2 cocktails for ladies', validity: 'Tonight only · Ends 11PM', price: 'FREE', emoji: '💃', isFeatured: true),
  _MockOffer(title: 'VIP Table Package', description: 'Reserve a table for 4 with bottle service', validity: 'Pre-book required', price: 'KES 8K', emoji: '🍾', isFeatured: false),
  _MockOffer(title: 'Happy Hour Drinks', description: 'Buy 2 get 1 free on selected cocktails', validity: '9PM – 11PM only', price: 'KES 400', emoji: '🍸', isFeatured: false),
  _MockOffer(title: 'Student Discount', description: '50% off entry with valid student ID', validity: 'Every Friday', price: 'KES 250', emoji: '🎓', isFeatured: false),
];
