import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../services/api_client.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleContinueWithPhone() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phone/OTP login is coming soon. Please sign in with email & password for now.'),
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      final user = auth.user;
      if (user != null) {
        bookingProvider.connectSocket(user.id);
      }

      try {
        final response = await ApiClient.get('/worker/profile');
        if (!mounted) return;
        final profileData = response['data']?['provider'] ?? response['data'];
        if (profileData != null) {
          final kycStatus = profileData['kyc']?['status'] ?? 'not_submitted';
          if (kycStatus == 'approved') {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (kycStatus == 'pending') {
            Navigator.pushReplacementNamed(context, '/kyc-pending');
          } else if (kycStatus == 'rejected') {
            Navigator.pushReplacementNamed(context, '/kyc-rejected');
          } else {
            Navigator.pushReplacementNamed(context, '/kyc-upload');
          }
          return;
        }
      } catch (_) {
        // No profile yet
      }
      Navigator.pushReplacementNamed(context, '/create-profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const _HeroSection(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _animController,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        26,
                        24,
                        MediaQuery.paddingOf(context).bottom + 20,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Login via OTP',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PhoneField(controller: _phoneController),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 52,
                            child: GradientButton(
                              text: 'Continue',
                              onPressed: _handleContinueWithPhone,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _DividerLabel(),
                          const SizedBox(height: 18),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _AirveatTextField(
                                  controller: _emailController,
                                  hintText: 'Email address',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? 'Enter a valid email'
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                _AirveatTextField(
                                  controller: _passwordController,
                                  hintText: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  keyboardType: TextInputType.text,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Password is required'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/forgot-password',
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 52,
                                  child: GradientButton(
                                    text: 'Sign In',
                                    isLoading: authProvider.isLoading,
                                    onPressed: _handleLogin,
                                    icon: Icons.arrow_forward_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _ProfessionalSignupCard(
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _TermsText(),
                        ],
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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      height: topPadding + 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071531), Color(0xFF0E3E75), Color(0xFF14538F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topPadding + 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.eco_rounded,
                color: Color(0xFF34D399),
                size: 26,
              ),
              const SizedBox(width: 6),
              Text(
                'Airveat',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              children: const [
                TextSpan(text: 'Join '),
                TextSpan(
                  text: '10,000+',
                  style: TextStyle(color: Color(0xFF34D399)),
                ),
                TextSpan(text: ' happy\nAirveat professionals'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to manage your jobs and start earning',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _TeamHero(),
            ),
          ),
          const SizedBox(height: 12),
          const _CarouselDots(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ProfessionalSignupCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfessionalSignupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign up as a Professional',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Join Airveat and start earning',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == 0 ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == 0
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCBD6E8).withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Text(
            '+91',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 26, color: const Color(0xFFE0E6F2)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Enter mobile number',
                hintStyle: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _AirveatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;

  const _AirveatTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143A71).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFFCBD6E8).withValues(alpha: 0.62),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: const Color(0xFFD7DEEC).withValues(alpha: 0.95),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: const Color(0xFFD7DEEC).withValues(alpha: 0.95),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(
      color: AppTheme.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: base.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy.',
            style: base.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 386,
          height: 200,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              const Positioned(
                bottom: 16,
                left: 2,
                child: _TeamMember(
                  height: 128,
                  shirtWidth: 58,
                  hair: Color(0xFF151A28),
                  skin: Color(0xFFDFA272),
                  pose: _Pose.crossed,
                ),
              ),
              const Positioned(
                bottom: 14,
                left: 57,
                child: _TeamMember(
                  height: 146,
                  shirtWidth: 64,
                  hair: Color(0xFF171520),
                  skin: Color(0xFFCA8758),
                  pose: _Pose.relaxed,
                ),
              ),
              const Positioned(
                bottom: 8,
                left: 122,
                child: _TeamMember(
                  height: 174,
                  shirtWidth: 76,
                  hair: Color(0xFF20140F),
                  skin: Color(0xFFC98758),
                  pose: _Pose.crossed,
                ),
              ),
              const Positioned(
                bottom: 8,
                right: 118,
                child: _TeamMember(
                  height: 166,
                  shirtWidth: 70,
                  hair: Color(0xFF1D1210),
                  skin: Color(0xFFD39565),
                  pose: _Pose.folder,
                ),
              ),
              const Positioned(
                bottom: 10,
                right: 57,
                child: _TeamMember(
                  height: 168,
                  shirtWidth: 70,
                  hair: Color(0xFF7A4C2C),
                  skin: Color(0xFFD29561),
                  pose: _Pose.flag,
                  hat: true,
                ),
              ),
              const Positioned(
                bottom: 14,
                right: 2,
                child: _TeamMember(
                  height: 146,
                  shirtWidth: 64,
                  hair: Color(0xFF15151B),
                  skin: Color(0xFFC38255),
                  pose: _Pose.crossed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Pose { crossed, relaxed, folder, flag }

class _TeamMember extends StatelessWidget {
  final double height;
  final double shirtWidth;
  final Color hair;
  final Color skin;
  final _Pose pose;
  final bool hat;

  const _TeamMember({
    required this.height,
    required this.shirtWidth,
    required this.hair,
    required this.skin,
    required this.pose,
    this.hat = false,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = height * 0.24;
    final shirtHeight = height * 0.47;

    return SizedBox(
      width: shirtWidth + 12,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: headSize + 38,
            child: Container(
              width: shirtWidth * 0.72,
              height: height * 0.28,
              decoration: const BoxDecoration(
                color: Color(0xFF315D96),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: headSize + 17,
            child: Container(
              width: shirtWidth,
              height: shirtHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF096BF4), Color(0xFF004BD2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          Positioned(
            top: headSize + 52,
            child: Text(
              'Airveat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: math.max(7, shirtWidth * 0.14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: headSize + 26,
            left: 0,
            child: _Arm(width: shirtWidth * 0.38, skin: skin, angle: -0.38),
          ),
          Positioned(
            top: headSize + 26,
            right: 0,
            child: _Arm(width: shirtWidth * 0.38, skin: skin, angle: 0.38),
          ),
          if (pose == _Pose.folder)
            Positioned(
              top: headSize + 58,
              right: 2,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: shirtWidth * 0.34,
                  height: shirtWidth * 0.50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (pose == _Pose.flag)
            Positioned(
              top: headSize + 18,
              right: 0,
              child: SizedBox(
                width: 22,
                height: 58,
                child: Stack(
                  children: [
                    Positioned(
                      left: 5,
                      top: 2,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.white),
                    ),
                    Positioned(
                      left: 7,
                      top: 2,
                      child: Container(
                        width: 18,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            'Airveat',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: headSize * 0.58,
            child: Container(
              width: headSize * 0.42,
              height: headSize * 0.34,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: hat ? 14 : 0,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                color: skin,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: hat ? 12 : 0,
            child: Container(
              width: headSize * 1.03,
              height: headSize * 0.50,
              decoration: BoxDecoration(
                color: hair,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(headSize),
                ),
              ),
            ),
          ),
          if (hat)
            Positioned(
              top: 0,
              child: Container(
                width: headSize * 1.28,
                height: headSize * 0.30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E3C7),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Arm extends StatelessWidget {
  final double width;
  final Color skin;
  final double angle;

  const _Arm({
    required this.width,
    required this.skin,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: skin,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

