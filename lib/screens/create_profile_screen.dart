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
    'cleaning', 'deep-cleaning', 'kitchen-cleaning', 'sanitization',
    'plumbing', 'pipe-repair', 'tap-installation', 'drain-cleaning',
    'electrical', 'wiring', 'fan-installation',
    'painting', 'interior-painting', 'touch-up',
  ];
  final Set<String> _selectedSkills = {};
  final List<String> _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final Set<String> _selectedDays = {};
  final List<String> _timeSlots = ['09:00-10:00', '10:00-11:00', '11:00-12:00', '12:00-13:00', '14:00-15:00', '15:00-16:00', '16:00-17:00', '17:00-18:00'];
  final Set<String> _selectedSlots = {};

  @override
  void dispose() { _addressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  const SizedBox(width: 48),
                  Expanded(child: Text('Setup Profile', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                  const SizedBox(width: 48),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Skills', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text('Select the skills you can offer', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _allSkills.map((skill) {
                          final selected = _selectedSkills.contains(skill);
                          return GestureDetector(
                            onTap: () => setState(() => selected ? _selectedSkills.remove(skill) : _selectedSkills.add(skill)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: selected ? AppTheme.primaryGradient : null,
                                color: selected ? null : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: selected ? null : Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                              ),
                              child: Text(skill, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      Text('Available Days', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _days.map((day) {
                          final selected = _selectedDays.contains(day);
                          return GestureDetector(
                            onTap: () => setState(() => selected ? _selectedDays.remove(day) : _selectedDays.add(day)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: selected ? AppTheme.primaryGradient : null,
                                color: selected ? null : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: selected ? null : Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                              ),
                              child: Text(day[0].toUpperCase() + day.substring(1, 3), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      Text('Time Slots', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _timeSlots.map((slot) {
                          final selected = _selectedSlots.contains(slot);
                          return GestureDetector(
                            onTap: () => setState(() => selected ? _selectedSlots.remove(slot) : _selectedSlots.add(slot)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: selected ? AppTheme.primaryGradient : null,
                                color: selected ? null : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: selected ? null : Border.all(color: AppTheme.textMuted.withValues(alpha: 0.2)),
                              ),
                              child: Text(slot, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textSecondary)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      Text('Location', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressCtrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(hintText: 'Your work area / address', prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted)),
                      ),
                      const SizedBox(height: 36),

                      Consumer<ProfileProvider>(
                        builder: (_, provider, __) => GradientButton(
                          text: 'Create Profile',
                          icon: Icons.check_circle_rounded,
                          isLoading: provider.isLoading,
                          onPressed: (_selectedSkills.isNotEmpty && _selectedDays.isNotEmpty && _selectedSlots.isNotEmpty) ? _handleCreate : null,
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
    final availability = _selectedDays.map((day) => {
      'dayOfWeek': day,
      'slots': _selectedSlots.toList(),
    }).toList();

    final provider = context.read<ProfileProvider>();
    final success = await provider.createProfile(
      skills: _selectedSkills.toList(),
      availability: availability,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to create profile'), backgroundColor: AppTheme.error));
    }
  }
}
