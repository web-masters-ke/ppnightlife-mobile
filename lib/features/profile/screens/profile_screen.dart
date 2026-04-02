import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

// ── Mock data ──────────────────────────────────────────────────────────────

const _kBadges = [
  _Badge('🏆', 'Club Legend', 'Checked in 50+ times', true),
  _Badge('🎵', 'Music Head', 'Rated 20+ DJs', true),
  _Badge('🌙', 'Night Owl', '5 nights in a row', true),
  _Badge('💜', 'Vibe Master', '500 reactions given', true),
  _Badge('🎉', 'Party Starter', 'Hosted an event', false),
  _Badge('👑', 'VIP Regular', 'VIP 3 venues', false),
  _Badge('🔥', 'Trendsetter', 'Top post of the week', false),
  _Badge('💰', 'Big Tipper', 'Tipped KES 10k+', false),
];

const _kActivities = [
  _Activity('📍', 'Checked in at Club Insomnia', '2h ago', true),
  _Activity('❤️', 'Reacted to DJ Pulse\'s post', '5h ago', false),
  _Activity('🎵', 'Rated DJ Kevo — 5 stars', '1d ago', false),
  _Activity('💜', 'Followed Alchemist Bar', '2d ago', false),
  _Activity('📍', 'Checked in at K1 Fao', '3d ago', true),
];

const _kLevelTitles = [
  'Newcomer', 'Night Crawler', 'Scene Kid', 'Regular',
  'Night Owl', 'Club Hopper', 'VIP', 'Night Legend', 'Club God', 'Party Icon',
];

// ── Data models ─────────────────────────────────────────────────────────────

class _Badge {
  final String emoji;
  final String title;
  final String desc;
  final bool earned;
  const _Badge(this.emoji, this.title, this.desc, this.earned);
}

class _Activity {
  final String emoji;
  final String text;
  final String time;
  final bool isCheckin;
  const _Activity(this.emoji, this.text, this.time, this.isCheckin);
}

// ── Screen ──────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _ProfileHeader(isDark: isDark, tabController: _tabController),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(isDark: isDark),
            _PostsTab(isDark: isDark),
            _ConnectionsTab(isDark: isDark),
            _BadgesTab(isDark: isDark),
            _ActivityTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends ConsumerStatefulWidget {
  final bool isDark;
  final TabController tabController;

  const _ProfileHeader({
    required this.isDark,
    required this.tabController,
  });

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (xfile == null) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      await ApiService().uploadProfilePhoto(user.userId, bytes, xfile.name, mime);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile photo updated!'),
          backgroundColor: AppColors.purple,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final tabController = widget.tabController;
    final user = ref.watch(authProvider).user;
    final xp = user?.xpPoints ?? 0;
    final level = user?.level ?? 1;
    final xpNext = (level + 1) * 500;
    final xpPct = (xp / xpNext).clamp(0.0, 1.0);
    final levelTitle = level < _kLevelTitles.length ? _kLevelTitles[level] : 'Legend';

    // Adaptive colors
    final headerBg1 = isDark ? const Color(0xFF1A1230) : const Color(0xFFEDE9FF);
    final headerBg2 = isDark ? AppColors.bgDark : AppColors.bgLight;
    final appBarIconColor = isDark ? Colors.white : AppColors.purple;
    final tabBarBg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: tabBarBg,
      actions: [
        GestureDetector(
          onTap: () => ref.read(themeProvider.notifier).toggle(),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: HugeIcon(
              icon: isDark ? HugeIcons.strokeRoundedSun01 : HugeIcons.strokeRoundedMoon01,
              size: 17,
              color: isDark ? AppColors.orange : AppColors.purple,
            ),
          ),
        ),
        IconButton(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedSettings01, size: 22, color: appBarIconColor),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => _SettingsSheet(isDark: isDark, ref: ref),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Container(
          color: tabBarBg,
          child: TabBar(
            controller: tabController,
            indicatorColor: AppColors.purple,
            indicatorWeight: 2,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Posts'),
              Tab(text: 'Connections'),
              Tab(text: 'Badges'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [headerBg1, headerBg2],
                ),
              ),
            ),
            Positioned(
              top: 90,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Avatar + name row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                                border: Border.all(
                                  color: isDark ? AppColors.bgDark : AppColors.bgLight,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withOpacity(0.35),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                              child: _uploadingPhoto
                                  ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : ClipOval(
                                      child: user?.profilePhoto != null && (user!.profilePhoto!).isNotEmpty
                                          ? Image.network(
                                              user.profilePhoto!,
                                              fit: BoxFit.cover,
                                              width: 76, height: 76,
                                              errorBuilder: (_, __, ___) => const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 34, color: Colors.white)),
                                            )
                                          : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 34, color: Colors.white)),
                                    ),
                            ),
                            // Camera overlay
                            Positioned(
                              bottom: 3,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white54, width: 1),
                                  ),
                                  child: const Center(
                                    child: HugeIcon(icon: HugeIcons.strokeRoundedCamera01, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            // Level badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.bgDark, width: 1.5),
                                ),
                                child: Text(
                                  'Lv.$level',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.name ?? 'Alex Maina',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    levelTitle,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              user?.username != null ? '@${user!.username}' : (user?.email.split('@').first ?? ''),
                              style: TextStyle(
                                color: isDark ? Colors.white60 : AppColors.textMutedLight,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Streak badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B00).withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🔥', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${user?.streakDays ?? 0} day streak',
                                        style: const TextStyle(
                                          color: Color(0xFFFF6B00),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // XP bar
                  _XpBar(xpPct: xpPct, xp: xp, xpNext: xpNext, level: level, isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── XP Bar ───────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final double xpPct;
  final int xp;
  final int xpNext;
  final int level;
  final bool isDark;
  const _XpBar({required this.xpPct, required this.xp, required this.xpNext, required this.level, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimaryLight;
    final mutedColor = isDark ? Colors.white54 : AppColors.textMutedLight;
    final trackColor = isDark ? Colors.white12 : Colors.black12;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: Text(
                '⚡ $xp XP',
                style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '$xp / $xpNext XP to Lv.${level + 1}',
              style: TextStyle(color: mutedColor, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(height: 6, width: double.infinity, color: trackColor),
              FractionallySizedBox(
                widthFactor: xpPct.clamp(0.0, 1.0),
                child: Container(
                  height: 6,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final bool isDark;
  const _OverviewTab({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(
            children: [
              _StatItem(value: '${user?.checkinCount ?? 0}', label: 'Nights Out', isDark: isDark),
              _VertDivider(isDark: isDark),
              _StatItem(value: '${(user?.followersCount ?? 0) + (user?.followingCount ?? 0)}', label: 'Connections', isDark: isDark),
              _VertDivider(isDark: isDark),
              _StatItem(value: '${user?.followersCount ?? 0}', label: 'Followers', isDark: isDark),
              _VertDivider(isDark: isDark),
              _StatItem(value: '${user?.postsCount ?? 0}', label: 'Posts', isDark: isDark),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // XP + gamification card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⚡ ${user?.xpPoints ?? 0} XP',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Builder(builder: (context) {
                final lvl = user?.level ?? 1;
                final xp = user?.xpPoints ?? 0;
                final xpNext = (lvl + 1) * 500;
                return Row(
                  children: [
                    _XpLevelCircle(level: lvl, isDark: isDark),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lvl < _kLevelTitles.length ? _kLevelTitles[lvl] : 'Legend',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            'Level $lvl — ${xpNext - xp} XP to next level',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(height: 7, color: isDark ? Colors.white12 : Colors.black12),
                                FractionallySizedBox(
                                  widthFactor: (xp / xpNext).clamp(0.0, 1.0),
                                  child: Container(
                                    height: 7,
                                    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$xp / $xpNext XP',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              // Streak row
              Row(
                children: [
                  Expanded(
                    child: _GamificationStat(
                      emoji: '🔥',
                      value: '${user?.streakDays ?? 0}',
                      label: 'Day Streak',
                      color: const Color(0xFFFF6B00),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GamificationStat(
                      emoji: '🏅',
                      value: '0',
                      label: 'Badges',
                      color: AppColors.purple,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GamificationStat(
                      emoji: '📍',
                      value: '${user?.checkinCount ?? 0}',
                      label: 'Check-ins',
                      color: AppColors.cyan,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Bio
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bio', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Text(
                user?.bio?.isNotEmpty == true
                    ? user!.bio!
                    : 'Nightlife enthusiast 🌙 Always finding the best parties.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Settings menu
        _MenuSection(
          title: 'Account',
          items: [
            _MenuItem(icon: HugeIcons.strokeRoundedUser, label: 'Edit Profile', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Edit profile coming soon'),
                behavior: SnackBarBehavior.floating,
              ));
            }, isDark: isDark),
            _MenuItem(icon: HugeIcons.strokeRoundedShield01, label: 'Privacy & Security', onTap: () {
              showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _PrivacySheet(isDark: isDark, ref: ref),
              );
            }, isDark: isDark),
            _MenuItem(icon: HugeIcons.strokeRoundedNotification01, label: 'Notifications', onTap: () {
              showModalBottomSheet(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (_) => _NotifPrefsSheet(isDark: isDark, ref: ref),
              );
            }, isDark: isDark),
          ],
          isDark: isDark,
        ),

        const SizedBox(height: 14),

        _MenuSection(
          title: 'More',
          items: [
            _MenuItem(icon: HugeIcons.strokeRoundedHelpCircle, label: 'Help & Support', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Help & Support: support@partypeople.app'),
                behavior: SnackBarBehavior.floating,
              ));
            }, isDark: isDark),
            _MenuItem(icon: HugeIcons.strokeRoundedInformationCircle, label: 'About PartyPeople', onTap: () {
              showAboutDialog(context: context, applicationName: 'PartyPeople', applicationVersion: '1.0.0');
            }, isDark: isDark),
            _MenuItem(
              icon: HugeIcons.strokeRoundedLogout01,
              label: 'Sign Out',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? AppColors.bgCardDark : Colors.white,
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out', style: TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                }
              },
              isDark: isDark,
              isDestructive: true,
            ),
          ],
          isDark: isDark,
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _XpLevelCircle extends StatelessWidget {
  final int level;
  final bool isDark;
  const _XpLevelCircle({required this.level, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [BoxShadow(color: AppColors.purple.withOpacity(0.4), blurRadius: 12)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Lv',
            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
          ),
          Text(
            '$level',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1),
          ),
        ],
      ),
    );
  }
}

class _GamificationStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _GamificationStat({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badges Tab ───────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  final bool isDark;
  const _BadgesTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final earned = _kBadges.where((b) => b.earned).toList();
    final locked = _kBadges.where((b) => !b.earned).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Earned count header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${earned.length} of ${_kBadges.length} Badges Earned',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Keep going to unlock more!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _BadgeSectionLabel(label: 'Earned', isDark: isDark),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: earned.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) => _BadgeCard(badge: earned[i], isDark: isDark),
        ),

        const SizedBox(height: 20),

        _BadgeSectionLabel(label: 'Locked', isDark: isDark),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: locked.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, i) => _BadgeCard(badge: locked[i], isDark: isDark, locked: true),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _BadgeSectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _BadgeSectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final _Badge badge;
  final bool isDark;
  final bool locked;

  const _BadgeCard({required this.badge, required this.isDark, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: locked
            ? (isDark ? AppColors.bgCardDark : AppColors.bgCardLight)
            : AppColors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked
              ? (isDark ? AppColors.borderDark : AppColors.borderLight)
              : AppColors.purple.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            badge.emoji,
            style: TextStyle(fontSize: 26, color: locked ? null : null),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: locked
                        ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  badge.desc,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!locked)
            const HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle01, size: 16, color: AppColors.purple),
          if (locked)
            HugeIcon(
              icon: HugeIcons.strokeRoundedLockPassword,
              size: 14,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
        ],
      ),
    );
  }
}

// ── Activity Tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends StatefulWidget {
  final bool isDark;
  const _ActivityTab({required this.isDark});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  List<_Activity> _activities = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  Future<void> _loadActivity() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().getCheckinHistory();
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _activities = items.map((c) => _Activity(
            '📍',
            'Checked in at ${(c['venue'] as Map<String, dynamic>?)?['name'] ?? 'a venue'}',
            _fmtTime(c['createdAt'] as String?),
            true,
          )).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _activities = _kActivities.toList(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak calendar preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Check-in Streak', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
                    ),
                    child: Text(
                      '🔥 ${_activities.length} check-ins',
                      style: const TextStyle(color: Color(0xFFFF6B00), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _StreakCalendar(isDark: isDark, activeDays: _activities.length.clamp(0, 28)),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Recent activity list
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text('Recent Activity', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ),
              if (_loading)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
              else if (_activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('No activity yet', style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                )
              else
                ..._activities.asMap().entries.map((entry) {
                  final i = entry.key;
                  final act = entry.value;
                  return Column(
                    children: [
                      _ActivityRow(activity: act, isDark: isDark),
                      if (i < _activities.length - 1)
                        Divider(height: 0.5, color: isDark ? AppColors.borderDark : AppColors.borderLight, indent: 52),
                    ],
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  final bool isDark;
  final int activeDays;
  const _StreakCalendar({required this.isDark, this.activeDays = 12});

  @override
  Widget build(BuildContext context) {
    const totalDays = 28;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalDays,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final isActive = i >= totalDays - activeDays;
        final isToday = i == totalDays - 1;
        return Container(
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : (isDark ? Colors.white10 : Colors.black.withAlpha(20)),
            borderRadius: BorderRadius.circular(5),
            border: isToday
                ? Border.all(color: AppColors.purple, width: 2)
                : null,
          ),
        );
      },
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _Activity activity;
  final bool isDark;

  const _ActivityRow({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: activity.isCheckin
                  ? AppColors.purple.withOpacity(0.12)
                  : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(13)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(activity.emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Text(
            activity.time,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final bool isDark;

  const _StatItem({required this.value, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  final bool isDark;
  const _VertDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  final bool isDark;

  const _MenuSection({required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (i < items.length - 1)
                    Divider(
                      height: 0.5,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      indent: 52,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.red
        : isDark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 20, color: isDestructive ? AppColors.red : AppColors.purple),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
            ),
            trailing ??
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
          ],
        ),
      ),
    );
  }
}

// ── Posts Tab ─────────────────────────────────────────────────────────────────
class _PostsTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _PostsTab({required this.isDark});

  @override
  ConsumerState<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends ConsumerState<_PostsTab> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) { setState(() => _loading = false); return; }
    try {
      final res = await ApiService().getUserPosts(user.userId);
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _posts = items; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _fmt(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text('No posts yet', style: TextStyle(fontSize: 15, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.purple,
      onRefresh: () async { setState(() => _loading = true); await _load(); },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final p = _posts[i];
          final content = p['content'] as String? ?? '';
          final likes = (p['reactionCount'] as num?)?.toInt() ?? 0;
          final comments = (p['commentCount'] as num?)?.toInt() ?? 0;
          final time = _fmt(p['createdAt'] as String?);
          final type = p['type'] as String? ?? '';
          final badge = type == 'checkin' ? '📍' : type == 'dj_update' ? '🎵' : type == 'photo' ? '📸' : '🎉';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(badge, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(p['venue']?['name'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(time, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ]),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(content, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                HugeIcon(icon: HugeIcons.strokeRoundedHeartAdd, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                const SizedBox(width: 4),
                Text('$likes', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                const SizedBox(width: 14),
                HugeIcon(icon: HugeIcons.strokeRoundedMessage01, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                const SizedBox(width: 4),
                Text('$comments', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
              ]),
            ]),
          );
        },
      ),
    );
  }
}

// ── Connections Tab ───────────────────────────────────────────────────────────
class _ConnectionsTab extends ConsumerStatefulWidget {
  final bool isDark;
  const _ConnectionsTab({required this.isDark});

  @override
  ConsumerState<_ConnectionsTab> createState() => _ConnectionsTabState();
}

class _ConnectionsTabState extends ConsumerState<_ConnectionsTab> with SingleTickerProviderStateMixin {
  late final TabController _tc;
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  bool _loadingFollowers = true;
  bool _loadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 2, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  Future<void> _loadConnections() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() { _loadingFollowers = false; _loadingFollowing = false; });
      return;
    }
    try {
      final res = await ApiService().getFollowers(user.userId);
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _followers = items; _loadingFollowers = false; });
    } catch (_) { if (mounted) setState(() => _loadingFollowers = false); }
    try {
      final res = await ApiService().getFollowing(user.userId);
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _following = items; _loadingFollowing = false; });
    } catch (_) { if (mounted) setState(() => _loadingFollowing = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(children: [
      TabBar(
        controller: _tc,
        indicatorColor: AppColors.purple,
        labelColor: AppColors.purple,
        unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        tabs: [
          Tab(text: 'Followers (${_followers.length})'),
          Tab(text: 'Following (${_following.length})'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _tc,
          children: [
            _UserList(users: _followers, loading: _loadingFollowers, isDark: isDark, emptyMsg: 'No followers yet'),
            _UserList(users: _following, loading: _loadingFollowing, isDark: isDark, emptyMsg: 'Not following anyone yet'),
          ],
        ),
      ),
    ]);
  }
}

class _UserList extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final bool loading;
  final bool isDark;
  final String emptyMsg;
  const _UserList({required this.users, required this.loading, required this.isDark, required this.emptyMsg});

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final Set<String> _following = {};

  Future<void> _toggleFollow(String userId) async {
    final isFollowing = _following.contains(userId);
    setState(() => isFollowing ? _following.remove(userId) : _following.add(userId));
    try {
      if (isFollowing) {
        await ApiService().unfollowUser(userId);
      } else {
        await ApiService().followUser(userId);
      }
    } catch (_) {
      if (mounted) setState(() => isFollowing ? _following.add(userId) : _following.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    if (widget.loading) return const Center(child: CircularProgressIndicator(color: AppColors.purple));
    if (widget.users.isEmpty) {
      return Center(child: Text(widget.emptyMsg, style: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final u = widget.users[i];
        final userId = u['id'] as String? ?? u['_id'] as String? ?? '';
        final name = u['name'] as String? ?? 'User';
        final photo = u['profilePhoto'] as String?;
        final isFollowing = _following.contains(userId);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
              child: photo != null
                  ? ClipOval(child: Image.network(photo, fit: BoxFit.cover))
                  : const Center(child: Text('👤', style: TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ),
            if (userId.isNotEmpty)
              GestureDetector(
                onTap: () => _toggleFollow(userId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isFollowing ? null : AppColors.primaryGradient,
                    color: isFollowing ? (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight) : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing ? Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight) : null,
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isFollowing ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight) : Colors.white,
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ── Settings Sheet (gear button) ─────────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  final bool isDark;
  final WidgetRef ref;
  const _SettingsSheet({required this.isDark, required this.ref});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text('Settings', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _MenuSection(
                    title: 'Account',
                    items: [
                      _MenuItem(icon: HugeIcons.strokeRoundedUser, label: 'Edit Profile', isDark: isDark, onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile coming soon'), behavior: SnackBarBehavior.floating));
                      }),
                      _MenuItem(icon: HugeIcons.strokeRoundedShield01, label: 'Privacy & Security', isDark: isDark, onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                            builder: (_) => _PrivacySheet(isDark: isDark, ref: ref));
                      }),
                      _MenuItem(icon: HugeIcons.strokeRoundedNotification01, label: 'Notifications', isDark: isDark, onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                            builder: (_) => _NotifPrefsSheet(isDark: isDark, ref: ref));
                      }),
                    ],
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  _MenuSection(
                    title: 'More',
                    items: [
                      _MenuItem(icon: HugeIcons.strokeRoundedHelpCircle, label: 'Help & Support', isDark: isDark, onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('support@partypeople.app'), behavior: SnackBarBehavior.floating));
                      }),
                      _MenuItem(icon: HugeIcons.strokeRoundedInformationCircle, label: 'About PartyPeople', isDark: isDark, onTap: () {
                        showAboutDialog(context: context, applicationName: 'PartyPeople', applicationVersion: '1.0.0');
                      }),
                      _MenuItem(
                        icon: HugeIcons.strokeRoundedLogout01,
                        label: 'Sign Out',
                        isDestructive: true,
                        isDark: isDark,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text('Are you sure you want to sign out?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Sign Out', style: TextStyle(color: AppColors.red))),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref.read(authProvider.notifier).logout();
                          }
                        },
                      ),
                    ],
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Privacy Settings Sheet ───────────────────────────────────────────────────
class _PrivacySheet extends StatefulWidget {
  final bool isDark;
  final WidgetRef ref;
  const _PrivacySheet({required this.isDark, required this.ref});

  @override
  State<_PrivacySheet> createState() => _PrivacySheetState();
}

class _PrivacySheetState extends State<_PrivacySheet> {
  bool _privateProfile = false;
  bool _showLocation = true;
  bool _allowTagging = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // defaults — backend returns these fields on profile if set
  }

  Future<void> _save() async {
    final user = widget.ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ApiService().updateUser(user.userId, {
        'settings': {
          'privateProfile': _privateProfile,
          'showLocation': _showLocation,
          'allowTagging': _allowTagging,
        }
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          _ToggleRow(label: 'Private Profile', subtitle: 'Only followers see your activity', value: _privateProfile, isDark: isDark, onChanged: (v) => setState(() => _privateProfile = v)),
          _ToggleRow(label: 'Show Location', subtitle: 'Show your city on your profile', value: _showLocation, isDark: isDark, onChanged: (v) => setState(() => _showLocation = v)),
          _ToggleRow(label: 'Allow Tagging', subtitle: 'Let others tag you in posts', value: _allowTagging, isDark: isDark, onChanged: (v) => setState(() => _allowTagging = v)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 48, width: double.infinity,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Notification Prefs Sheet ──────────────────────────────────────────────────
class _NotifPrefsSheet extends StatefulWidget {
  final bool isDark;
  final WidgetRef ref;
  const _NotifPrefsSheet({required this.isDark, required this.ref});

  @override
  State<_NotifPrefsSheet> createState() => _NotifPrefsSheetState();
}

class _NotifPrefsSheetState extends State<_NotifPrefsSheet> {
  bool _djUpdates = true;
  bool _socialActivity = true;
  bool _offers = true;
  bool _checkins = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // defaults — backend returns these fields on profile if set
  }

  Future<void> _save() async {
    final user = widget.ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ApiService().updateUser(user.userId, {
        'settings': {
          'notifications': {
            'djUpdates': _djUpdates,
            'socialActivity': _socialActivity,
            'offers': _offers,
            'checkins': _checkins,
          }
        }
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          _ToggleRow(label: 'DJ Updates', subtitle: 'New sets, announcements from DJs you follow', value: _djUpdates, isDark: isDark, onChanged: (v) => setState(() => _djUpdates = v)),
          _ToggleRow(label: 'Social Activity', subtitle: 'Likes, comments, new followers', value: _socialActivity, isDark: isDark, onChanged: (v) => setState(() => _socialActivity = v)),
          _ToggleRow(label: 'Offers & Deals', subtitle: 'Venue offers and promotions', value: _offers, isDark: isDark, onChanged: (v) => setState(() => _offers = v)),
          _ToggleRow(label: 'Check-in Activity', subtitle: 'When your connections check in nearby', value: _checkins, isDark: isDark, onChanged: (v) => setState(() => _checkins = v)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              height: 48, width: double.infinity,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(child: _saving
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text('Save Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.subtitle, required this.value, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.purple),
      ]),
    );
  }
}
