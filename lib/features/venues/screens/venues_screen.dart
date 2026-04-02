import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';

const _kAreas = ['All Areas', 'Westlands', 'CBD', 'Kilimani', 'Lavington', 'Karen', 'Parklands', 'Upperhill'];
const _kAreaParams = [null, 'westlands', 'cbd', 'kilimani', 'lavington', 'karen', 'parklands', 'upperhill'];

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  final _searchController = TextEditingController();
  int _selectedFilter = 0;
  int _selectedArea = 0;
  final _filters = ['Nearby', 'Trending', 'Open Now', 'Clubs', 'Bars', 'Rooftops'];
  List<Map<String, dynamic>> _apiVenues = [];
  List<Map<String, dynamic>> _liveDJs = [];
  bool _loadingVenues = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _loadLiveDJs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadVenues(searchQuery: _searchController.text.trim());
    });
  }

  Future<void> _loadLiveDJs() async {
    try {
      final res = await ApiService().getLiveDJs();
      final data = res.data['data'];
      final items = ((data is List ? data : data?['items']) as List? ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() => _liveDJs = items);
    } catch (_) {}
  }

  Future<void> _loadVenues({String? searchQuery}) async {
    setState(() => _loadingVenues = true);
    try {
      final area = _kAreaParams[_selectedArea];
      final q = searchQuery ?? _searchController.text.trim();
      final res = await ApiService().getVenues(limit: 30, area: q.isNotEmpty ? null : area, search: q.isNotEmpty ? q : null);
      setState(() {
        final data = res.data['data'];
        _apiVenues = ((data is List ? data : data?['items']) as List? ?? []).cast<Map<String, dynamic>>();
        _loadingVenues = false;
      });
    } catch (_) {
      setState(() => _loadingVenues = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: const Text('Explore Venues'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search venues, events...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    prefixIcon: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      size: 20,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),
          ),

          // Filters
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => setState(() => _selectedFilter = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: _selectedFilter == index ? AppColors.primaryGradient : null,
                      color: _selectedFilter == index
                          ? null
                          : isDark
                              ? AppColors.bgElevatedDark
                              : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _selectedFilter == index
                            ? Colors.transparent
                            : isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                      ),
                    ),
                    child: Text(
                      _filters[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedFilter == index ? FontWeight.w600 : FontWeight.w400,
                        color: _selectedFilter == index
                            ? Colors.white
                            : isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Area filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _kAreas.length,
                itemBuilder: (context, index) {
                  final sel = _selectedArea == index;
                  return GestureDetector(
                    onTap: () {
                      if (_selectedArea != index) {
                        setState(() => _selectedArea = index);
                        _loadVenues();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.purple.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? AppColors.purple : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                      ),
                      child: Text(
                        _kAreas[index],
                        style: TextStyle(
                          fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color: sel ? AppColors.purple : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Live Now section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Now',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      const SizedBox(width: 8),
                      if (_liveDJs.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: Text('${_liveDJs.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: _liveDJs.isEmpty
                        ? Center(child: Text('No live DJs right now', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _liveDJs.length,
                            itemBuilder: (ctx, i) => _LiveDJCard(dj: _liveDJs[i], isDark: isDark),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // All venues
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'All Venues',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _loadingVenues
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
                : _apiVenues.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Text('🏙️', style: TextStyle(fontSize: 48)),
                                SizedBox(height: 12),
                                Text('No venues found', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final v = _apiVenues[i];
                            final mock = _MockVenue(
                              name: v['name'] as String? ?? 'Venue',
                              emoji: '🏛️',
                              gradient: AppColors.primaryGradient,
                              peopleCount: (v['currentCheckins'] as num?)?.toInt() ?? 0,
                              distance: '— km',
                            );
                            final vId = v['venueId'] as String? ?? v['id'] as String? ?? '';
                            return GestureDetector(
                              onTap: vId.isNotEmpty ? () => context.push('/venue/$vId') : null,
                              child: _VenueListTile(venue: mock, isDark: isDark),
                            );
                          },
                          childCount: _apiVenues.length,
                        ),
                      ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ── Live DJ Card (real API) ───────────────────────────────────────────────────
class _LiveDJCard extends StatelessWidget {
  final Map<String, dynamic> dj;
  final bool isDark;
  const _LiveDJCard({required this.dj, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = dj['djName'] as String? ?? dj['name'] as String? ?? 'DJ';
    final venueName = (dj['venue'] as Map?)?['name'] as String? ?? dj['venueName'] as String? ?? '';
    final photo = dj['profilePhoto'] as String?;
    final checkins = dj['checkinCount'] ?? dj['guestCount'] ?? 0;
    final gradients = [AppColors.primaryGradient, AppColors.warmGradient, AppColors.cyanGradient];
    final grad = gradients[name.hashCode.abs() % gradients.length];

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: grad),
        child: Stack(
          children: [
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(photo, width: 160, height: 180, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            // dark overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)]),
              ),
            ),
            Center(
              child: photo == null
                  ? const Text('🎧', style: TextStyle(fontSize: 46))
                  : const SizedBox(),
            ),
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(6)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.white),
                    SizedBox(width: 4),
                    Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10, left: 10, right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (venueName.isNotEmpty)
                    Text(venueName, style: const TextStyle(fontSize: 11, color: Colors.white70),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (checkins > 0)
                    Row(children: [
                      const Icon(Icons.people_outline, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text('$checkins crowd', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live Venue Card (fallback mock) ───────────────────────────────────────────
class _LiveVenueCard extends StatelessWidget {
  final _MockVenue venue;
  final bool isDark;

  const _LiveVenueCard({required this.venue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: venue.gradient,
        ),
        child: Stack(
          children: [
            Center(child: Text(venue.emoji, style: const TextStyle(fontSize: 50))),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        '${venue.peopleCount} inside',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueListTile extends StatelessWidget {
  final _MockVenue venue;
  final bool isDark;

  const _VenueListTile({required this.venue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: venue.gradient,
              ),
              child: Center(child: Text(venue.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.green.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.green),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 2),
                      Text(
                        venue.distance,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 2),
                      Text(
                        '${venue.peopleCount} people',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 20,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ],
        ),
    );
  }
}

class _MockVenue {
  final String name;
  final String emoji;
  final Gradient gradient;
  final int peopleCount;
  final String distance;

  const _MockVenue({
    required this.name,
    required this.emoji,
    required this.gradient,
    required this.peopleCount,
    required this.distance,
  });
}

