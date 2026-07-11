import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/profile_provider.dart';
import '../widgets/gradient_button.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});
  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _addressCtrl = TextEditingController();
  final List<String> _allSkills = [
    'cleaning',
    'deep-cleaning',
    'kitchen-cleaning',
    'sanitization',
    'plumbing',
    'pipe-repair',
    'tap-installation',
    'drain-cleaning',
    'electrical',
    'wiring',
    'fan-installation',
    'painting',
    'interior-painting',
    'touch-up',
  ];
  final Set<String> _selectedSkills = {};

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Setup Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Your Skills'),
                      const SizedBox(height: 8),
                      Text(
                        'Select the skills you can offer',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSkills.map((skill) {
                          final selected = _selectedSkills.contains(skill);
                          return GestureDetector(
                            onTap: () => setState(
                              () => selected
                                  ? _selectedSkills.remove(skill)
                                  : _selectedSkills.add(skill),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: selected ? null : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: selected
                                    ? null
                                    : Border.all(
                                        color: AppTheme.textMuted.withValues(
                                          alpha: 0.16,
                                        ),
                                      ),
                              ),
                              child: Text(
                                skill,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      _sectionTitle('Location'),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Your work area / address',
                          prefixIcon: Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      Consumer<ProfileProvider>(
                        builder: (_, provider, __) => GradientButton(
                          text: 'Create Profile',
                          icon: Icons.check_circle_rounded,
                          isLoading: provider.isLoading,
                          onPressed: _selectedSkills.isNotEmpty
                              ? _handleCreate
                              : null,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate() async {
    final provider = context.read<ProfileProvider>();
    final success = await provider.createProfile(
      skills: _selectedSkills.toList(),
      availability: const [],
      address: _addressCtrl.text.trim().isNotEmpty
          ? _addressCtrl.text.trim()
          : null,
    );

    if (!mounted) return;
    if (success) {
      // After creating a profile, the worker must complete KYC before accessing dashboard.
      Navigator.pushReplacementNamed(context, '/kyc-upload');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create profile'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
