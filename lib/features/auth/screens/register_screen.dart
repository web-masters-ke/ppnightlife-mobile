import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/pp_text_field.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class _RoleOption {
  final String id;
  final String label;
  final String desc;
  final String emoji;
  final Color color;

  const _RoleOption({
    required this.id,
    required this.label,
    required this.desc,
    required this.emoji,
    required this.color,
  });
}

const _roles = [
  _RoleOption(id: 'party-goer',  label: 'Party Goer',    desc: 'Discover venues & check in',    emoji: '🎉', color: AppColors.purple),
  _RoleOption(id: 'dj',          label: 'DJ',             desc: 'Manage live sets & earn tips',   emoji: '🎵', color: AppColors.pink),
  _RoleOption(id: 'venue-owner', label: 'Venue Owner',    desc: 'Manage your venue & DJs',        emoji: '🏛️', color: AppColors.cyan),
  _RoleOption(id: 'advertiser',  label: 'Advertiser',     desc: 'Run campaigns & reach crowds',   emoji: '📣', color: AppColors.orange),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> with SingleTickerProviderStateMixin {
  // Step 0 = role select, Step 1 = form, Step 2 = venue create (venue-owner only)
  int _step = 0;
  _RoleOption? _selectedRole;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _agreeTerms = false;

  // Venue creation (step 2)
  final _venueNameCtrl = TextEditingController();
  final _venueAddressCtrl = TextEditingController();
  final _venueAreaCtrl = TextEditingController();
  final _venuePhoneCtrl = TextEditingController();
  final _venueCapacityCtrl = TextEditingController();
  String _venueCategory = 'Club';
  bool _venueCreating = false;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _venueAreaCtrl.dispose();
    _venuePhoneCtrl.dispose();
    _venueCapacityCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _selectRole(_RoleOption role) {
    setState(() {
      _selectedRole = role;
      _step = 1;
    });
    _animController.reset();
    _animController.forward();
  }

  void _goBack() {
    if (_step == 2) {
      setState(() => _step = 1);
      _animController.reset();
      _animController.forward();
    } else if (_step == 1) {
      setState(() => _step = 0);
      _animController.reset();
      _animController.forward();
    } else {
      context.go('/login');
    }
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms to continue'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final error = await ref.read(authProvider.notifier).register({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'password': _passwordController.text,
      'role': _selectedRole!.id,
    });
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.red),
      );
      return;
    }
    final role = ref.read(authProvider).role;
    switch (role) {
      case 'venue_owner':
      case 'venue-owner':
        // Go to venue creation step first
        setState(() => _step = 2);
        _animController.reset();
        _animController.forward();
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

  Future<void> _createVenue() async {
    if (_venueNameCtrl.text.trim().isEmpty || _venueAddressCtrl.text.trim().isEmpty || _venueCapacityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venue name, address and capacity are required'), backgroundColor: AppColors.red),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _venueCreating = true);
    try {
      await ApiService().createVenue({
        'name': _venueNameCtrl.text.trim(),
        'address': _venueAddressCtrl.text.trim(),
        'area': _venueAreaCtrl.text.trim(),
        'phone': _venuePhoneCtrl.text.trim().isNotEmpty ? _venuePhoneCtrl.text.trim() : _phoneController.text.trim(),
        'category': _venueCategory,
        'capacity': int.tryParse(_venueCapacityCtrl.text.trim()) ?? 100,
        'location': {'latitude': -1.286389, 'longitude': 36.817223},
      });
    } catch (_) { /* non-blocking */ }
    if (!mounted) return;
    setState(() => _venueCreating = false);
    context.go('/merchant');
  }

  void _skipVenueCreation() => context.go('/merchant');

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      resizeToAvoidBottomInset: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.bgDark,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.bgDark,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Stack(
        fit: StackFit.expand,
        children: [
          // Background glows
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  (_selectedRole?.color ?? AppColors.purple).withOpacity(0.3),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.pink.withOpacity(0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _goBack,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.bgElevatedDark,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, size: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _step == 0 ? 'Create account' : _step == 1 ? 'Your details' : 'Your venue',
                            key: ValueKey(_step),
                            style: const TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.bgElevatedDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Text(
                          _selectedRole?.id == 'venue-owner'
                              ? 'Step ${_step + 1} of 3'
                              : 'Step ${_step + 1} of 2',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _step == 0 ? 0.33 : (_step == 1 ? 0.66 : 1.0),
                      backgroundColor: AppColors.bgElevatedDark,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
                      minHeight: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Step content ──────────────────────────────────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _step == 0
                        ? _RoleSelectStep(key: const ValueKey(0), onSelect: _selectRole)
                        : _step == 1
                            ? _RegisterFormStep(
                                key: const ValueKey(1),
                                selectedRole: _selectedRole!,
                                formKey: _formKey,
                                nameController: _nameController,
                                emailController: _emailController,
                                phoneController: _phoneController,
                                passwordController: _passwordController,
                                isLoading: _isLoading,
                                agreeTerms: _agreeTerms,
                                onAgreeChanged: (v) => setState(() => _agreeTerms = v),
                                onRegister: _register,
                                onSignIn: () => context.go('/login'),
                              )
                            : _VenueCreateStep(
                                key: const ValueKey(2),
                                nameCtrl: _venueNameCtrl,
                                addressCtrl: _venueAddressCtrl,
                                areaCtrl: _venueAreaCtrl,
                                phoneCtrl: _venuePhoneCtrl,
                                capacityCtrl: _venueCapacityCtrl,
                                category: _venueCategory,
                                onCategoryChanged: (v) => setState(() => _venueCategory = v),
                                creating: _venueCreating,
                                onCreate: _createVenue,
                                onSkip: _skipVenueCreation,
                              ),
                  ),
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

// ── Step 1: Role Select ───────────────────────────────────────────────────────
class _RoleSelectStep extends StatelessWidget {
  final void Function(_RoleOption) onSelect;

  const _RoleSelectStep({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Who are you?',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your role to personalise your experience',
            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.45), height: 1.4),
          ),
          const SizedBox(height: 24),

          // 2-column grid of role cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.9,
            children: _roles.map((role) => _RoleCard(role: role, onTap: () => onSelect(role))).toList(),
          ),

          const SizedBox(height: 28),

          // Already have account
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
                  children: const [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.purple),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _RoleOption role;
  final VoidCallback onTap;

  const _RoleCard({required this.role, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: role.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Text(role.emoji, style: const TextStyle(fontSize: 24))),
            ),
            const Spacer(),
            Text(
              role.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              role.desc,
              style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45), height: 1.3),
            ),
            const SizedBox(height: 8),
            // "Select" arrow
            Row(
              children: [
                Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: role.color)),
                const SizedBox(width: 3),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 13, color: role.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Register Form ─────────────────────────────────────────────────────
class _RegisterFormStep extends StatelessWidget {
  final _RoleOption selectedRole;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool agreeTerms;
  final void Function(bool) onAgreeChanged;
  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  const _RegisterFormStep({
    super.key,
    required this.selectedRole,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.isLoading,
    required this.agreeTerms,
    required this.onAgreeChanged,
    required this.onRegister,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selectedRole.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedRole.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(selectedRole.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedRole.label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selectedRole.color),
                    ),
                    Text(
                      selectedRole.desc,
                      style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Fill in your details',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Create your PartyPeople account',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45)),
          ),

          const SizedBox(height: 20),

          Form(
            key: formKey,
            child: Column(
              children: [
                PPTextField(
                  forceDark: true,
                  label: 'Full Name',
                  hint: 'Your name',
                  controller: nameController,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18, color: AppColors.textMutedDark),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 13),

                PPTextField(
                  forceDark: true,
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedMail01, size: 18, color: AppColors.textMutedDark),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 13),

                PPTextField(
                  forceDark: true,
                  label: 'Phone (optional)',
                  hint: '+254 7XX XXX XXX',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedSmartPhone01, size: 18, color: AppColors.textMutedDark),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 13),

                PPTextField(
                  forceDark: true,
                  label: 'Password',
                  hint: 'Min 8 characters',
                  controller: passwordController,
                  obscureText: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 18, color: AppColors.textMutedDark),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onRegister(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Terms checkbox
          GestureDetector(
            onTap: () => onAgreeChanged(!agreeTerms),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    gradient: agreeTerms ? AppColors.primaryGradient : null,
                    color: agreeTerms ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: agreeTerms ? Colors.transparent : AppColors.borderDark,
                      width: 1.5,
                    ),
                  ),
                  child: agreeTerms
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5), height: 1.4),
                      children: const [
                        TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                        TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          GradientButton(
            label: 'Create Account',
            onTap: onRegister,
            isLoading: isLoading,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [selectedRole.color, AppColors.pink],
            ),
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserAdd01, size: 18, color: Colors.white),
          ),

          const SizedBox(height: 20),

          Center(
            child: TextButton(
              onPressed: onSignIn,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
                  children: const [
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.purple),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Venue Create ──────────────────────────────────────────────────────
class _VenueCreateStep extends StatelessWidget {
  final TextEditingController nameCtrl, addressCtrl, areaCtrl, phoneCtrl, capacityCtrl;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final bool creating;
  final VoidCallback onCreate, onSkip;

  const _VenueCreateStep({
    super.key,
    required this.nameCtrl, required this.addressCtrl, required this.areaCtrl,
    required this.phoneCtrl, required this.capacityCtrl,
    required this.category, required this.onCategoryChanged,
    required this.creating, required this.onCreate, required this.onSkip,
  });

  static const _categories = ['Club', 'Bar', 'Rooftop', 'Lounge', 'Restaurant', 'Events Venue'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Text('🏛️', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Register Your Venue', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text('This will appear on the venues discovery page', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          _field('Venue Name *', nameCtrl, 'e.g. Club Insomnia'),
          const SizedBox(height: 12),
          _field('Address *', addressCtrl, 'e.g. Westlands, Nairobi'),
          const SizedBox(height: 12),
          _field('Area / Neighbourhood', areaCtrl, 'e.g. Westlands'),
          const SizedBox(height: 12),
          _field('Phone', phoneCtrl, '+254 7XX XXX XXX', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _field('Capacity *', capacityCtrl, 'e.g. 300', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((c) => GestureDetector(
              onTap: () => onCategoryChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: category == c ? AppColors.cyan.withOpacity(0.2) : AppColors.bgElevatedDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: category == c ? AppColors.cyan : AppColors.borderDark),
                ),
                child: Text(c, style: TextStyle(
                  fontSize: 12, fontWeight: category == c ? FontWeight.w700 : FontWeight.w400,
                  color: category == c ? AppColors.cyan : Colors.white54,
                )),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 50,
            child: GestureDetector(
              onTap: creating ? null : onCreate,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.cyan, Color(0xFF0EA5E9)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: creating
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('🏛️', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text('Create Venue & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: onSkip,
              child: Text('Skip for now — set up later in settings',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.6))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: AppColors.bgElevatedDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ],
    );
  }
}
