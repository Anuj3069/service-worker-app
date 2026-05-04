import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _animCtrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart));
    _animCtrl.forward();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); _phoneCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passCtrl.text, phone: _phoneCtrl.text.trim());
    if (success) {
      final user = auth.user;
      if (user != null) {
        context.read<BookingProvider>().connectSocket(user.id);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/create-profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _animCtrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 24)]),
                      child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text('Join as\nWorker', style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1.1)),
                    const SizedBox(height: 8),
                    Text('Create your worker account', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                    const SizedBox(height: 36),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(controller: _nameCtrl, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted)), validator: (v) => (v == null || v.length < 2) ? 'Name must be at least 2 characters' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted)), validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null),
                          const SizedBox(height: 16),
                          TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Phone number (optional)', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted))),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl, obscureText: _obscure, style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(hintText: 'Password', prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textMuted), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textMuted), onPressed: () => setState(() => _obscure = !_obscure))),
                            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(controller: _confirmCtrl, obscureText: true, style: const TextStyle(color: AppTheme.textPrimary), decoration: const InputDecoration(hintText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted)), validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null),
                          const SizedBox(height: 32),
                          Consumer<AuthProvider>(builder: (_, auth, __) => GradientButton(text: 'Create Account', isLoading: auth.isLoading, onPressed: _handleRegister, icon: Icons.arrow_forward_rounded)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                        GestureDetector(onTap: () => Navigator.pushReplacementNamed(context, '/login'), child: Text('Sign In', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
