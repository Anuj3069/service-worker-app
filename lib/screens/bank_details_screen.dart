import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/settlement_provider.dart';
import '../widgets/gradient_button.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final _formKey = GlobalKey<FormState>();
  final _holderNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Pre-fill from existing bank details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillBankDetails();
    });
  }

  void _prefillBankDetails() {
    final sp = context.read<SettlementProvider>();
    final bank = sp.bankDetails;
    if (bank != null) {
      _holderNameCtrl.text = bank['accountHolderName'] ?? '';
      _accountNumberCtrl.text = bank['accountNumber'] ?? '';
      _ifscCtrl.text = bank['ifscCode'] ?? '';
      _bankNameCtrl.text = bank['bankName'] ?? '';
      _upiCtrl.text = bank['upiId'] ?? '';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _holderNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _bankNameCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final sp = context.read<SettlementProvider>();
    final data = {
      'accountHolderName': _holderNameCtrl.text.trim(),
      'accountNumber': _accountNumberCtrl.text.trim(),
      'ifscCode': _ifscCtrl.text.trim().toUpperCase(),
      'bankName': _bankNameCtrl.text.trim(),
    };
    if (_upiCtrl.text.trim().isNotEmpty) {
      data['upiId'] = _upiCtrl.text.trim();
    }

    final success = await sp.saveBankDetails(data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank details saved successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sp.error?.replaceAll('Exception: ', '') ??
              'Failed to save bank details'),
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
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  AppTheme.textMuted.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Details',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'For receiving your payouts',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          color: AppTheme.success,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.primary
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Your bank details are used to transfer settlement payouts. Make sure the information is accurate.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          _buildField(
                            label: 'Account Holder Name',
                            controller: _holderNameCtrl,
                            icon: Icons.person_rounded,
                            hint: 'Enter full name as per bank account',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Account holder name is required';
                              }
                              return null;
                            },
                          ),

                          _buildField(
                            label: 'Account Number',
                            controller: _accountNumberCtrl,
                            icon: Icons.numbers_rounded,
                            hint: 'Enter 9-18 digit account number',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Account number is required';
                              }
                              final digits = RegExp(r'^\d{9,18}$');
                              if (!digits.hasMatch(v.trim())) {
                                return 'Account number must be 9-18 digits';
                              }
                              return null;
                            },
                          ),

                          _buildField(
                            label: 'IFSC Code',
                            controller: _ifscCtrl,
                            icon: Icons.code_rounded,
                            hint: 'e.g. HDFC0001234',
                            textCapitalization:
                                TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'IFSC code is required';
                              }
                              final ifsc = RegExp(
                                  r'^[A-Z]{4}0[A-Z0-9]{6}$');
                              if (!ifsc.hasMatch(v.trim().toUpperCase())) {
                                return 'Invalid IFSC format (e.g. HDFC0001234)';
                              }
                              return null;
                            },
                          ),

                          _buildField(
                            label: 'Bank Name',
                            controller: _bankNameCtrl,
                            icon: Icons.account_balance_rounded,
                            hint: 'e.g. HDFC Bank',
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Bank name is required';
                              }
                              return null;
                            },
                          ),

                          _buildField(
                            label: 'UPI ID (Optional)',
                            controller: _upiCtrl,
                            icon: Icons.qr_code_rounded,
                            hint: 'e.g. name@upi',
                            isOptional: true,
                          ),

                          const SizedBox(height: 32),

                          GradientButton(
                            text: 'Save Bank Details',
                            icon: Icons.save_rounded,
                            isLoading: _isSaving,
                            onPressed: _handleSave,
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: Text(
                              '🔒  Your details are encrypted and stored securely',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (isOptional) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Optional',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            validator: validator,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
