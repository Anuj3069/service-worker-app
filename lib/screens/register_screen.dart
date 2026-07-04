import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  String? _selectedGender;
  DateTime? _selectedDob;
  String? _dobError;
  late AnimationController _animCtrl;
  late Animation<Offset> _slide;

  static const _genderOptions = [
    {'value': 'male', 'label': 'Male', 'icon': Icons.male_rounded},
    {'value': 'female', 'label': 'Female', 'icon': Icons.female_rounded},
    {'value': 'other', 'label': 'Other', 'icon': Icons.transgender_rounded},
  ];

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? eighteenYearsAgo,
      firstDate: DateTime(now.year - 100),
      lastDate: eighteenYearsAgo,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobError = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutQuart));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final formValid = _formKey.currentState!.validate();
    setState(() {
      _dobError = _selectedDob == null ? 'Date of birth is required' : null;
    });
    if (!formValid || _selectedDob == null) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phone: _phoneCtrl.text.trim(),
      gender: _selectedGender!,
      dateOfBirth: _selectedDob!,
    );
    if (!mounted) return;
    if (success) {
      final user = auth.user;
      if (user != null) {
        bookingProvider.connectSocket(user.id);
      }
      Navigator.pushReplacementNamed(context, '/create-profile');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SlideTransition(
                position: _slide,
                child: FadeTransition(
                  opacity: _animCtrl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.24),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Join as Worker',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your worker account',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 34),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Full Name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 2)
                                  ? 'Name must be at least 2 characters'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Email address',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _fieldLabel('Mobile Number', required: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Enter your mobile number',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              validator: (v) {
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) {
                                  return 'Mobile number is required';
                                }
                                if (!RegExp(r'^\+?[\d\s-]{10,15}$')
                                    .hasMatch(value)) {
                                  return 'Enter a valid mobile number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('Gender', required: true),
                            const SizedBox(height: 8),
                            Row(
                              children: _genderOptions.map((opt) {
                                final selected = _selectedGender == opt['value'];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: opt != _genderOptions.last ? 10 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedGender = opt['value'] as String,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          gradient: selected
                                              ? AppTheme.primaryGradient
                                              : null,
                                          color: selected ? null : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: selected
                                              ? null
                                              : Border.all(
                                                  color: AppTheme.textMuted
                                                      .withValues(alpha: 0.25),
                                                ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              opt['icon'] as IconData,
                                              size: 20,
                                              color: selected
                                                  ? Colors.white
                                                  : AppTheme.textMuted,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              opt['label'] as String,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: selected
                                                    ? Colors.white
                                                    : AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            _fieldLabel('Date of Birth', required: true),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _pickDob,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _dobError != null
                                        ? AppTheme.error
                                        : AppTheme.textMuted.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cake_outlined,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedDob != null
                                          ? DateFormat('dd MMM yyyy').format(_selectedDob!)
                                          : 'Select date of birth',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: _selectedDob != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 18,
                                      color: AppTheme.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_dobError != null) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  _dobError!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textMuted,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: true,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Confirm Password',
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              validator: (v) => v != _passCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 32),
                            Consumer<AuthProvider>(
                              builder: (_, auth, __) => GradientButton(
                                text: 'Create Account',
                                isLoading: auth.isLoading,
                                onPressed: _handleRegister,
                                icon: Icons.arrow_forward_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                            child: Text(
                              'Sign In',
                              style: GoogleFonts.inter(
                                color: AppTheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, {bool required = false}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '(Required)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
