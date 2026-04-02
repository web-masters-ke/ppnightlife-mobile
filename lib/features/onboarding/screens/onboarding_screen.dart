import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/gradient_button.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final Gradient gradient;
  final IconData icon;
  final String emoji;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.emoji,
  });
}

final _pages = [
  const _OnboardingPage(
    title: 'Connect at the Party',
    subtitle: 'Discover who\'s at the same venue and connect in real-time. If you\'re in the same place, you should be socially connected.',
    gradient: AppColors.primaryGradient,
    icon: Icons.location_on_rounded,
    emoji: '🎉',
  ),
  const _OnboardingPage(
    title: 'Live Venue Feed',
    subtitle: 'See and share moments happening right now at your venue. Text, photos, and videos — just like the party deserves.',
    gradient: AppColors.warmGradient,
    icon: Icons.feed_rounded,
    emoji: '📸',
  ),
  const _OnboardingPage(
    title: 'Vibe with the DJ',
    subtitle: 'Request songs, vote on tracks, and tip your favourite DJ — all from your phone while you dance.',
    gradient: AppColors.cyanGradient,
    icon: Icons.music_note_rounded,
    emoji: '🎵',
  ),
  const _OnboardingPage(
    title: 'Your Night, Your World',
    subtitle: 'Whether you\'re a party goer, venue owner, advertiser, or DJ — PartyPeople is built for you.',
    gradient: AppColors.primaryGradient,
    icon: Icons.people_alt_rounded,
    emoji: '🌟',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgController;
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _contentController.reset();
    _contentController.forward();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.bgDark,
                  (page.gradient as LinearGradient).colors.first.withOpacity(0.15),
                  AppColors.bgDark,
                ],
              ),
            ),
          ),

          // Glow orbs
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (page.gradient as LinearGradient).colors.first.withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: size.height * 0.2,
            left: -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (page.gradient as LinearGradient).colors.last.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Page content
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final p = _pages[index];
              return _OnboardingPageWidget(
                page: p,
                contentFade: _contentFade,
                contentSlide: _contentSlide,
                size: size,
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 4,
                      spacing: 6,
                      activeDotColor: AppColors.purple,
                      dotColor: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Next / Get Started button
                  GradientButton(
                    label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                    gradient: page.gradient,
                    onTap: _next,
                    icon: _currentPage == _pages.length - 1
                        ? const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18)
                        : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 16),

                  // Skip
                  if (_currentPage < _pages.length - 1)
                    GestureDetector(
                      onTap: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
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

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final Size size;

  const _OnboardingPageWidget({
    required this.page,
    required this.contentFade,
    required this.contentSlide,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 200),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji icon in gradient circle
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: page.gradient,
                  boxShadow: [
                    BoxShadow(
                      color: (page.gradient as LinearGradient).colors.first.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    page.emoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: ShaderMask(
                shaderCallback: (bounds) => page.gradient.createShader(bounds),
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Subtitle
          FadeTransition(
            opacity: contentFade,
            child: SlideTransition(
              position: contentSlide,
              child: Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
