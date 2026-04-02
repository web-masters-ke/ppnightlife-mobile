import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../feed/screens/create_post_screen.dart';

// Provider for unread chat count — refreshed on shell mount
final _unreadCountProvider = FutureProvider<int>((ref) async {
  try {
    final res = await ApiService().getChatRooms();
    final rooms = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
    return rooms.fold<int>(0, (sum, r) => sum + ((r['unreadCount'] as num?)?.toInt() ?? 0));
  } catch (_) {
    return 0;
  }
});

class HomeShell extends ConsumerWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/venues')) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/wallet')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onNavTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/venues'); break;
      case 2: context.go('/chat'); break;
      case 3: context.go('/wallet'); break;
      case 4: context.go('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(_unreadCountProvider).valueOrNull ?? 0;

    final navBarColor = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
            border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : AppColors.purple.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  _NavItem(icon: HugeIcons.strokeRoundedHome01, activeIcon: HugeIcons.strokeRoundedHome09, label: 'Home', index: 0, currentIndex: currentIndex, onTap: () => _onNavTap(context, 0), isDark: isDark),
                  _NavItem(icon: HugeIcons.strokeRoundedLocation01, activeIcon: HugeIcons.strokeRoundedLocation04, label: 'Venues', index: 1, currentIndex: currentIndex, onTap: () => _onNavTap(context, 1), isDark: isDark),
                  // Center post button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showCreatePost(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Color(0x556C5CE7), blurRadius: 12, offset: Offset(0, 4))],
                            ),
                            child: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, size: 24, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _NavItem(icon: HugeIcons.strokeRoundedMessage01, activeIcon: HugeIcons.strokeRoundedMessage02, label: 'Chat', index: 2, currentIndex: currentIndex, onTap: () => _onNavTap(context, 2), isDark: isDark, badge: unread),
                  _NavItem(icon: HugeIcons.strokeRoundedUser, activeIcon: HugeIcons.strokeRoundedUserCircle, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: () => _onNavTap(context, 4), isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreatePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _CreatePostSheet(),
    );
  }
}

class _NavItem extends StatelessWidget {
  final List<List<dynamic>> icon;
  final List<List<dynamic>> activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool isDark;
  final int? badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final iconColor = isSelected ? AppColors.purple : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: HugeIcon(icon: isSelected ? activeIcon : icon, size: 22, color: iconColor),
                ),
                if (badge != null && badge! > 0)
                  Positioned(
                    top: 2, right: 2,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: AppColors.pink, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          badge! > 9 ? '9+' : '$badge',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.purple : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatePostSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 0, 12, bottomPad > 0 ? 0 : 12),
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad > 0 ? bottomPad + 8 : 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Create', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                _PostTypeButton(icon: HugeIcons.strokeRoundedTextFont, label: 'Text Post', gradient: AppColors.primaryGradient, onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CreatePostScreen(postType: 'text')));
                }),
                const SizedBox(width: 10),
                _PostTypeButton(icon: HugeIcons.strokeRoundedImage01, label: 'Photo', gradient: AppColors.warmGradient, onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CreatePostScreen(postType: 'photo')));
                }),
                const SizedBox(width: 10),
                _PostTypeButton(icon: HugeIcons.strokeRoundedVideo01, label: 'Video', gradient: AppColors.cyanGradient, onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const CreatePostScreen(postType: 'video')));
                }),
                const SizedBox(width: 10),
                _PostTypeButton(
                  icon: HugeIcons.strokeRoundedUserStory,
                  label: 'Story',
                  gradient: const LinearGradient(colors: [AppColors.pink, AppColors.orange]),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTypeButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _PostTypeButton({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: (gradient as LinearGradient).colors.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Center(child: HugeIcon(icon: icon, color: Colors.white, size: 24)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
