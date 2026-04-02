import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';

class _RoleOption {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final Gradient gradient;
  final Color glowColor;

  const _RoleOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.glowColor,
  });
}

final _roles = [
  const _RoleOption(
    id: 'party_goer',
    title: 'Party Goer',
    subtitle: 'Discover venues, connect with people & enjoy the night',
    emoji: '🎉',
    gradient: AppColors.primaryGradient,
    glowColor: AppColors.purple,
  ),
  const _RoleOption(
    id: 'venue_owner',
    title: 'Venue Owner',
    subtitle: 'Manage your venue, engage guests & grow your brand',
    emoji: '🏛️',
    gradient: AppColors.cyanGradient,
    glowColor: AppColors.cyan,
  ),
  const _RoleOption(
    id: 'advertiser',
    title: 'Event Advertiser',
    subtitle: 'Promote events, run ads & reach nightlife audiences',
    emoji: '📣',
    gradient: AppColors.warmGradient,
    glowColor: AppColors.orange,
  ),
  const _RoleOption(
    id: 'dj',
    title: 'DJ',
    subtitle: 'Accept song requests, receive tips & connect with fans',
    emoji: '🎵',
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.pink, AppColors.purple],
    ),
    glowColor: AppColors.pink,
  ),
];

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Header
              FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _animController, curve: const Interval(0, 0.5)),
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'Who are you?',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select your role to personalize your experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Role cards
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role.id;
                    final delay = index * 0.12;

                    return FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                        CurvedAnimation(
                          parent: _animController,
                          curve: Interval(delay + 0.2, delay + 0.8, curve: Curves.easeOut),
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animController,
                            curve: Interval(delay + 0.2, delay + 0.8, curve: Curves.easeOutCubic),
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRole = role.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? role.glowColor.withOpacity(0.1)
                                  : isDark
                                      ? AppColors.bgCardDark
                                      : AppColors.bgCardLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? role.glowColor.withOpacity(0.5)
                                    : isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: role.glowColor.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: isSelected ? role.gradient : null,
                                    color: isSelected
                                        ? null
                                        : isDark
                                            ? AppColors.bgElevatedDark
                                            : AppColors.bgElevatedLight,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: role.glowColor.withOpacity(0.3),
                                              blurRadius: 12,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(role.emoji, style: const TextStyle(fontSize: 26)),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        role.subtitle,
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Radio
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isSelected ? role.gradient : null,
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: isDark
                                                ? AppColors.borderDark
                                                : AppColors.borderLight,
                                            width: 2,
                                          ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Continue
              GradientButton(
                label: 'Continue',
                onTap: _selectedRole != null ? () => context.go('/profile-setup') : null,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
