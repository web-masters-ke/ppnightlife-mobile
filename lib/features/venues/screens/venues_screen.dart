import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import 'dj_room_screen.dart';

const _kAreas = ['All Areas', 'Westlands', 'CBD', 'Kilimani', 'Lavington', 'Karen', 'Parklands', 'Upperhill'];
const _kAreaParams = [null, 'westlands', 'cbd', 'kilimani', 'lavington', 'karen', 'parklands', 'upperhill'];
const _kVenueTypes = ['All', 'Clubs', 'Bars', 'Rooftops', 'Lounges', 'Restaurants'];

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({super.key});

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  int _selectedArea = 0;
  int _selectedType = 0;
  bool _openNow = false;
  bool _sortTrending = false;
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
    _searchFocus.dispose();
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
      final body = res.data['data'] ?? res.data;
      // Backend returns { live: [...], count } — not items
      final raw = ((body['live'] as List?) ??
              (body is List ? body : body?['items'] as List?) ??
              [])
          .cast<Map<String, dynamic>>();

      // Enrich each live set with user profile + venue name
      final enriched = await Future.wait(raw.map((set) async {
        final djId = set['djId'] as String? ?? set['dj_id'] as String? ?? '';
        final venueId = set['venueId'] as String? ?? set['venue_id'] as String? ?? '';
        Map<String, dynamic> userInfo = {};
        Map<String, dynamic> venueInfo = {};
        try {
          if (djId.isNotEmpty) {
            final u = await ApiService().getUser(djId);
            userInfo = (u.data['data'] ?? u.data) as Map<String, dynamic>? ?? {};
          }
        } catch (_) {}
        try {
          if (venueId.isNotEmpty) {
            final v = await ApiService().getVenue(venueId);
            venueInfo = (v.data['data'] ?? v.data) as Map<String, dynamic>? ?? {};
          }
        } catch (_) {}
        return {
          ...set,
          'djId': djId,
          'venueId': venueId,
          'djName': userInfo['name'] as String? ?? userInfo['djName'] as String? ?? 'DJ',
          'name': userInfo['name'] as String? ?? 'DJ',
          'profilePhoto': userInfo['profilePhoto'] as String?,
          'venueName': venueInfo['name'] as String? ?? '',
          'venue': {'venueId': venueId, 'name': venueInfo['name'] as String? ?? ''},
          'checkinCount': (venueInfo['currentCheckins'] as num?)?.toInt() ?? 0,
          'nowPlaying': userInfo['nowPlaying'] as String?,
        };
      }));

      if (mounted) setState(() => _liveDJs = enriched);
    } catch (_) {}
  }

  Future<void> _loadVenues({String? searchQuery}) async {
    setState(() => _loadingVenues = true);
    try {
      final area = _kAreaParams[_selectedArea];
      final q = searchQuery ?? _searchController.text.trim();
      final res = await ApiService().getVenues(
        limit: 30,
        area: q.isNotEmpty ? null : area,
        search: q.isNotEmpty ? q : null,
      );
      setState(() {
        final data = res.data['data'];
        _apiVenues = ((data is List ? data : data?['items']) as List? ?? []).cast<Map<String, dynamic>>();
        _loadingVenues = false;
      });
    } catch (_) {
      setState(() => _loadingVenues = false);
    }
  }

  void _toggleSearch() {
    HapticFeedback.selectionClick();
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      Future.delayed(const Duration(milliseconds: 100), () => _searchFocus.requestFocus());
    } else {
      _searchController.clear();
      _searchFocus.unfocus();
      _loadVenues();
    }
  }

  void _showFiltersSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FiltersSheet(
        isDark: isDark,
        selectedArea: _selectedArea,
        selectedType: _selectedType,
        openNow: _openNow,
        sortTrending: _sortTrending,
        onApply: (area, type, openNow, trending) {
          setState(() {
            _selectedArea = area;
            _selectedType = type;
            _openNow = openNow;
            _sortTrending = trending;
          });
          _loadVenues();
        },
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
          // ── Stretched App Bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: isDark ? AppColors.bgDark : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: isDark ? 0 : 0.5,
            automaticallyImplyLeading: false,
            // Collapsed title row
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchOpen
                  ? TextField(
                      key: const ValueKey('search'),
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      decoration: InputDecoration(
                        hintText: 'Search venues, events...',
                        hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : Align(
                      key: const ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Explore Venues',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _searchOpen
                      ? HugeIcon(key: const ValueKey('close'), icon: HugeIcons.strokeRoundedCancel01, size: 22,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                      : HugeIcon(key: const ValueKey('search'), icon: HugeIcons.strokeRoundedSearch01, size: 22,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                onPressed: _toggleSearch,
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal, size: 22,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    if (_selectedArea != 0 || _selectedType != 0 || _openNow || _sortTrending)
                      Positioned(top: -2, right: -2, child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
                      )),
                  ],
                ),
                onPressed: _showFiltersSheet,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nairobi Nightlife',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedBuilding01, size: 14, color: AppColors.purple),
                      const SizedBox(width: 4),
                      Text('${_apiVenues.length} venues found',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.purple)),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── DJ Rooms section ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('DJ Rooms', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                    const SizedBox(width: 8),
                    if (_liveDJs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('${_liveDJs.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red)),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: _liveDJs.isEmpty
                        ? Center(child: Text('No live DJs right now',
                            style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontSize: 13)))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _liveDJs.length,
                            itemBuilder: (ctx, i) => _LiveDJCard(
                              dj: _liveDJs[i],
                              isDark: isDark,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => DjRoomScreen(dj: _liveDJs[i]),
                              )),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 18)),

          // ── All Venues header ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(children: [
                Expanded(child: Text('All Venues', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ))),
                if (_selectedArea != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_kAreas[_selectedArea],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
                  ),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Venues list ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _loadingVenues
                ? const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.purple),
                    )))
                : _apiVenues.isEmpty
                    ? const SliverToBoxAdapter(child: Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(children: [
                          Text('🏙️', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No venues found', style: TextStyle(fontSize: 14)),
                        ]),
                      )))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final v = _apiVenues[i];
                            final vId = v['venueId'] as String? ?? v['id'] as String? ?? '';
                            return GestureDetector(
                              onTap: vId.isNotEmpty ? () => context.push('/venue/$vId') : null,
                              child: _VenueListTile(venue: v, isDark: isDark),
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

// ── Filters Bottom Sheet ──────────────────────────────────────────────────────
class _FiltersSheet extends StatefulWidget {
  final bool isDark;
  final int selectedArea, selectedType;
  final bool openNow, sortTrending;
  final void Function(int area, int type, bool openNow, bool trending) onApply;

  const _FiltersSheet({
    required this.isDark,
    required this.selectedArea, required this.selectedType,
    required this.openNow, required this.sortTrending,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late int _area, _type;
  late bool _openNow, _trending;

  @override
  void initState() {
    super.initState();
    _area = widget.selectedArea;
    _type = widget.selectedType;
    _openNow = widget.openNow;
    _trending = widget.sortTrending;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      padding: EdgeInsets.fromLTRB(16, 16, 16, botPad > 0 ? botPad : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgElevatedDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('Filters', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ))),
            GestureDetector(
              onTap: () { setState(() { _area = 0; _type = 0; _openNow = false; _trending = false; }); },
              child: Text('Reset', style: const TextStyle(fontSize: 13, color: AppColors.purple, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),

          _sectionLabel('Area', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_kAreas.length, (i) => GestureDetector(
              onTap: () => setState(() => _area = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _area == i ? AppColors.purple.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _area == i ? AppColors.purple : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                child: Text(_kAreas[i], style: TextStyle(
                  fontSize: 12, fontWeight: _area == i ? FontWeight.w700 : FontWeight.w400,
                  color: _area == i ? AppColors.purple : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                )),
              ),
            )),
          ),
          const SizedBox(height: 16),

          _sectionLabel('Venue Type', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_kVenueTypes.length, (i) => GestureDetector(
              onTap: () => setState(() => _type = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _type == i ? AppColors.purple.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _type == i ? AppColors.purple : (isDark ? AppColors.borderDark : AppColors.borderLight)),
                ),
                child: Text(_kVenueTypes[i], style: TextStyle(
                  fontSize: 12, fontWeight: _type == i ? FontWeight.w700 : FontWeight.w400,
                  color: _type == i ? AppColors.purple : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                )),
              ),
            )),
          ),
          const SizedBox(height: 16),

          _sectionLabel('Options', isDark),
          const SizedBox(height: 8),
          _ToggleTile(label: 'Open Now', value: _openNow, isDark: isDark, onChanged: (v) => setState(() => _openNow = v)),
          const SizedBox(height: 6),
          _ToggleTile(label: 'Sort by Trending', value: _trending, isDark: isDark, onChanged: (v) => setState(() => _trending = v)),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity, height: 46,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onApply(_area, _type, _openNow, _trending);
              },
              child: Container(
                decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(text, style: TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600,
    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
  ));
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value, isDark;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.label, required this.value, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgDark : AppColors.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Row(children: [
          Expanded(child: Text(label, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ))),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40, height: 22,
            decoration: BoxDecoration(
              gradient: value ? AppColors.primaryGradient : null,
              color: value ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
              borderRadius: BorderRadius.circular(11),
              border: value ? null : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18, height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Live DJ Card ──────────────────────────────────────────────────────────────
class _LiveDJCard extends StatelessWidget {
  final Map<String, dynamic> dj;
  final bool isDark;
  final VoidCallback onTap;
  const _LiveDJCard({required this.dj, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = dj['djName'] as String? ?? dj['name'] as String? ?? 'DJ';
    final venueName = (dj['venue'] as Map?)?['name'] as String? ?? dj['venueName'] as String? ?? '';
    final photo = dj['profilePhoto'] as String?;
    final checkins = dj['checkinCount'] ?? dj['guestCount'] ?? 0;
    final gradients = [AppColors.primaryGradient, AppColors.warmGradient, AppColors.cyanGradient];
    final grad = gradients[name.hashCode.abs() % gradients.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: grad),
        child: Stack(children: [
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(photo, width: 160, height: 180, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)]),
            ),
          ),
          Center(child: photo == null ? const Text('🎧', style: TextStyle(fontSize: 46)) : const SizedBox()),
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 6, color: Colors.white),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
          // Tap hint
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
              child: const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 14, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 10, left: 10, right: 10,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Venue List Tile ───────────────────────────────────────────────────────────
class _VenueListTile extends StatelessWidget {
  final Map<String, dynamic> venue;
  final bool isDark;
  const _VenueListTile({required this.venue, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = venue['name'] as String? ?? 'Venue';
    final checkins = (venue['currentCheckins'] as num?)?.toInt() ?? 0;
    final area = venue['area'] as String? ?? '';
    final photo = venue['coverPhoto'] as String? ?? venue['photo'] as String?;
    final isActive = (venue['status'] as String?) == 'active';
    final gradients = [AppColors.primaryGradient, AppColors.warmGradient, AppColors.cyanGradient];
    final grad = gradients[name.hashCode.abs() % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: photo != null
              ? Image.network(photo, width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(grad))
              : _placeholder(grad),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (isActive ? AppColors.green : AppColors.textMutedDark).withOpacity(0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: (isActive ? AppColors.green : AppColors.textMutedDark).withOpacity(0.3)),
              ),
              child: Text(isActive ? 'Open' : 'Closed', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: isActive ? AppColors.green : AppColors.textMutedDark,
              )),
            ),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            if (area.isNotEmpty) ...[
              HugeIcon(icon: HugeIcons.strokeRoundedLocation01, size: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(width: 2),
              Text(area, style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              const SizedBox(width: 8),
            ],
            if (checkins > 0) ...[
              HugeIcon(icon: HugeIcons.strokeRoundedUserGroup, size: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              const SizedBox(width: 2),
              Text('$checkins inside', style: TextStyle(fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
            ],
          ]),
        ])),
        HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
      ]),
    );
  }

  Widget _placeholder(Gradient grad) => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(gradient: grad),
    child: const Center(child: Text('🏛️', style: TextStyle(fontSize: 22))),
  );
}

// Legacy classes kept for compatibility
class _MockVenue {
  final String name, emoji, distance;
  final Gradient gradient;
  final int peopleCount;
  const _MockVenue({required this.name, required this.emoji, required this.gradient, required this.peopleCount, required this.distance});
}
