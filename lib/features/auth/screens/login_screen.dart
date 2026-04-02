import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/pp_text_field.dart';
import '../../../core/providers/auth_provider.dart';

final _demoAccounts = [
  _Demo(label: 'Party Goer', emoji: '🎉', email: 'partygoer@demo.pp', password: 'demo1234', color: AppColors.purple),
  _Demo(label: 'Venue Owner', emoji: '🏛️', email: 'venue@demo.pp', password: 'demo1234', color: AppColors.cyan),
  _Demo(label: 'DJ', emoji: '🎵', email: 'dj@demo.pp', password: 'demo1234', color: AppColors.pink),
  _Demo(label: 'Advertiser', emoji: '📣', email: 'ads@demo.pp', password: 'demo1234', color: AppColors.orange),
];

class _Demo {
  final String label, emoji, email, password;
  final Color color;
  const _Demo({required this.label, required this.emoji, required this.email, required this.password, required this.color});
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  late AnimationController _anim;
  late Animation<double> _logoFade;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _logoFade = CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.5));
    _formFade = CurvedAnimation(parent: _anim, curve: const Interval(0.3, 1.0));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final error = await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.red),
      );
      return;
    }
    final role = ref.read(authProvider).role;
    _navigateByRole(role);
  }

  void _navigateByRole(String role) {
    switch (role) {
      case 'venue_owner':
      case 'venue-owner':
        context.go('/merchant');
        break;
      case 'dj':
        context.go('/dj-studio');
        break;
      case 'advertiser':
        context.go('/advertiser');
        break;
      default:
        context.go('/');
    }
  }

  void _showForgotPassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ForgotSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      resizeToAvoidBottomInset: false,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.bgCardDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // Glows
          Positioned(top: -80, right: -60,
            child: _Glow(color: AppColors.purple, size: 280)),
          Positioned(top: size.height * 0.35, left: -60,
            child: _Glow(color: AppColors.pink, size: 220, opacity: 0.2)),

          // Logo strip — top 32% of screen
          FadeTransition(
            opacity: _logoFade,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: topPad + 10),
                child: SizedBox(
                  height: size.height * 0.26,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                          BoxShadow(color: AppColors.purple.withOpacity(0.45), blurRadius: 30, spreadRadius: 4),
                          BoxShadow(color: AppColors.pink.withOpacity(0.2), blurRadius: 50),
                        ]),
                        child: Image.asset('assets/images/logo.png', width: 64, height: 64),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                        child: const Text('PartyPeople',
                          style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 22,
                            fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                      ),
                      const SizedBox(height: 2),
                      Text('The nightlife social platform',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Form card — bottom 74% of screen, never overlaps logo
          Positioned(
            top: topPad + size.height * 0.26,
            left: 0, right: 0, bottom: 0,
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.bgCardDark,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                    border: Border(
                      top: BorderSide(color: AppColors.borderDark),
                      left: BorderSide(color: AppColors.borderDark),
                      right: BorderSide(color: AppColors.borderDark),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, botPad + 8),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle
                          Center(child: Container(width: 32, height: 3,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: AppColors.borderHoverDark,
                              borderRadius: BorderRadius.circular(2)))),

                          const Text('Welcome back 👋',
                            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 19,
                              fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 1),
                          Text('Sign in to your account',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),

                          const SizedBox(height: 12),

                          PPTextField(
                            forceDark: true,
                            label: 'Email',
                            hint: 'you@example.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                              child: HugeIcon(icon: HugeIcons.strokeRoundedMail01, size: 18, color: AppColors.textMutedDark)),
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your email';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          PPTextField(
                            forceDark: true,
                            label: 'Password',
                            hint: '••••••••',
                            controller: _passCtrl,
                            obscureText: true,
                            prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                              child: HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 18, color: AppColors.textMutedDark)),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your password';
                              if (v.length < 6) return 'Too short';
                              return null;
                            },
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPassword,
                              style: TextButton.styleFrom(padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 26),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: const Text('Forgot password?',
                                style: TextStyle(fontSize: 11, color: AppColors.purple, fontWeight: FontWeight.w500)),
                            ),
                          ),

                          const SizedBox(height: 4),

                          GradientButton(label: 'Sign In', onTap: _login, isLoading: _loading, height: 44),

                          const SizedBox(height: 10),

                          // Demo accounts divider
                          Row(children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.07))),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Demo accounts',
                                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.28)))),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.07))),
                          ]),

                          const SizedBox(height: 8),

                          // Demo tiles — one row
                          Row(
                            children: _demoAccounts.asMap().entries.map((e) {
                              final i = e.key; final acc = e.value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _emailCtrl.text = acc.email;
                                    _passCtrl.text = acc.password;
                                  }),
                                  child: Container(
                                    margin: EdgeInsets.only(right: i < _demoAccounts.length - 1 ? 6 : 0),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: acc.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: acc.color.withOpacity(0.28))),
                                    child: Column(children: [
                                      Text(acc.emoji, style: const TextStyle(fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(acc.label, style: TextStyle(fontSize: 8,
                                        fontWeight: FontWeight.w600, color: acc.color),
                                        textAlign: TextAlign.center, maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    ]),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              child: RichText(text: TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4)),
                                children: const [TextSpan(text: 'Sign Up',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.purple))],
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _Glow({required this.color, required this.size, this.opacity = 0.3});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent]),
      ),
    );
  }
}

// ── Forgot Password Sheet ─────────────────────────────────────────────────────
class _ForgotSheet extends StatefulWidget {
  @override State<_ForgotSheet> createState() => _ForgotSheetState();
}

class _ForgotSheetState extends State<_ForgotSheet> {
  final _ctrl = TextEditingController();
  bool _sent = false, _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (mounted) setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, botPad + 24),
      decoration: const BoxDecoration(
        color: AppColors.bgElevatedDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.borderDark),
          left: BorderSide(color: AppColors.borderDark),
          right: BorderSide(color: AppColors.borderDark))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(color: AppColors.borderHoverDark, borderRadius: BorderRadius.circular(2)))),
        if (!_sent) ...[
          const Text('Reset password',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 5),
          Text("Enter your email and we'll send a reset link.",
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45))),
          const SizedBox(height: 18),
          PPTextField(
            forceDark: true,
            hint: 'you@example.com', controller: _ctrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Padding(padding: EdgeInsets.symmetric(horizontal: 12),
              child: HugeIcon(icon: HugeIcons.strokeRoundedMail01, size: 18, color: AppColors.textMutedDark)),
            textInputAction: TextInputAction.done, onSubmitted: (_) => _send()),
          const SizedBox(height: 14),
          GradientButton(label: 'Send Reset Link', onTap: _send, isLoading: _loading, height: 48),
        ] else ...[
          const Center(child: Text('📬', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 14),
          const Center(child: Text('Check your inbox',
            style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
          const SizedBox(height: 6),
          Center(child: Text('Reset link sent to\n${_ctrl.text}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45), height: 1.5))),
          const SizedBox(height: 18),
          GradientButton(label: 'Done', onTap: () => Navigator.pop(context), height: 48),
        ],
      ]),
    );
  }
}
