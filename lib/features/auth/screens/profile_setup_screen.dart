import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/pp_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // Progress
              Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: i <= _currentStep ? AppColors.primaryGradient : null,
                        color: i <= _currentStep
                            ? null
                            : isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              Text(
                'Set up your profile',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_currentStep + 1} of 3',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),

              const SizedBox(height: 36),

              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(isDark),
                ),
              ),

              GradientButton(
                label: _currentStep == 2 ? 'Finish Setup' : 'Next',
                isLoading: _isLoading,
                icon: _currentStep == 2
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                onTap: () async {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    setState(() => _isLoading = true);
                    await Future.delayed(const Duration(milliseconds: 1200));
                    if (mounted) context.go('/');
                  }
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey(0),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar picker
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, color: Colors.white, size: 50),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purple,
                        border: Border.all(
                          color: isDark ? AppColors.bgDark : AppColors.bgLight,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PPTextField(
              label: 'Username',
              hint: '@yourname',
              controller: _usernameController,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Text(
                  '@',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about yourself',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            PPTextField(
              label: 'Bio',
              hint: 'Write a short bio...',
              controller: _bioController,
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Text(
              'This helps others discover and connect with you',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turn on notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Stay updated on what\'s happening at venues near you',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 28),
            _NotifTile(
              icon: Icons.message_rounded,
              title: 'Messages',
              subtitle: 'When someone messages you',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _NotifTile(
              icon: Icons.location_on_rounded,
              title: 'Venue Activity',
              subtitle: 'Live updates at your venue',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _NotifTile(
              icon: Icons.music_note_rounded,
              title: 'DJ Requests',
              subtitle: 'Song request status updates',
              isDark: isDark,
            ),
          ],
        );
    }
  }
}

class _NotifTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  State<_NotifTile> createState() => _NotifTileState();
}

class _NotifTileState extends State<_NotifTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _enabled ? AppColors.primaryGradient : null,
              color: _enabled ? null : (widget.isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: _enabled ? Colors.white : AppColors.textMutedDark, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            activeColor: AppColors.purple,
          ),
        ],
      ),
    );
  }
}
