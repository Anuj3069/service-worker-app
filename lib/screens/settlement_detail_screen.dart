import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/settlement.dart';
import '../providers/settlement_provider.dart';
import '../widgets/glass_card.dart';

class SettlementDetailScreen extends StatefulWidget {
  const SettlementDetailScreen({super.key});

  @override
  State<SettlementDetailScreen> createState() => _SettlementDetailScreenState();
}

class _SettlementDetailScreenState extends State<SettlementDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  Settlement? _settlement;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      Navigator.pop(context);
      return;
    }

    final sp = context.read<SettlementProvider>();
    final settlement = await sp.fetchSettlementDetail(id);
    if (mounted) {
      setState(() {
        _settlement = settlement;
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warning;
      case 'processing':
        return AppTheme.accepted;
      case 'settled':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'processing':
        return Icons.sync_rounded;
      case 'settled':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                            color: AppTheme.textMuted.withValues(alpha: 0.2),
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
                            'Settlement Details',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (_settlement != null)
                            Text(
                              '#${_settlement!.id.substring(_settlement!.id.length > 8 ? _settlement!.id.length - 8 : 0).toUpperCase()}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                                fontFeatures: [
                                  const FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary))
                    : _settlement == null
                        ? Center(
                            child: Text(
                              'Settlement not found',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textMuted),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnim,
                            child: _buildContent(),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final s = _settlement!;
    final color = _statusColor(s.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status + Amount Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(s.status), color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    s.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '₹${s.totalAmount.toInt()}',
                  style: GoogleFonts.outfit(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${s.bookingCount} job${s.bookingCount != 1 ? 's' : ''} included',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Admin Note (UTR or Rejection) ──
          if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (s.isRejected
                              ? AppTheme.error
                              : AppTheme.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      s.isRejected
                          ? Icons.error_outline_rounded
                          : Icons.receipt_long_rounded,
                      color:
                          s.isRejected ? AppTheme.error : AppTheme.success,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.isRejected
                              ? 'Rejection Reason'
                              : 'Transaction Reference',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.adminNote!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Timeline ──
          _sectionLabel('Timeline'),
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _timelineRow(
                  icon: Icons.send_rounded,
                  color: AppTheme.primary,
                  label: 'Requested',
                  date: _formatDate(s.requestedAt),
                  isFirst: true,
                ),
                if (s.isSettled || s.isProcessing)
                  _timelineRow(
                    icon: Icons.sync_rounded,
                    color: AppTheme.accepted,
                    label: 'Processing',
                    date: 'Started by admin',
                  ),
                if (s.isSettled)
                  _timelineRow(
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.success,
                    label: 'Settled',
                    date: _formatDate(s.settledAt),
                    isLast: true,
                  ),
                if (s.isRejected)
                  _timelineRow(
                    icon: Icons.cancel_rounded,
                    color: AppTheme.error,
                    label: 'Rejected',
                    date: 'By admin',
                    isLast: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Booking Breakdown ──
          _sectionLabel('Booking Breakdown'),
          ...s.bookingIds.map((b) {
            if (b is SettlementBooking) {
              return GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${b.id.substring(b.id.length > 8 ? b.id.length - 8 : 0).toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFeatures: [
                                const FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Price: ₹${b.price.toInt()} • ${b.status}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${b.payout.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              );
            }
            // Plain string booking ID
            return GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Booking #${b.toString().substring(b.toString().length > 8 ? b.toString().length - 8 : 0).toUpperCase()}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // ── Bank Details Snapshot ──
          if (s.bankSnapshot != null) ...[
            _sectionLabel('Bank Details Used'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _bankRow('Account Holder',
                      s.bankSnapshot!.accountHolderName ?? '—'),
                  _bankRow('Account Number',
                      s.bankSnapshot!.maskedAccountNumber),
                  _bankRow(
                      'IFSC Code', s.bankSnapshot!.ifscCode ?? '—'),
                  _bankRow(
                      'Bank Name', s.bankSnapshot!.bankName ?? '—'),
                  if (s.bankSnapshot!.upiId != null &&
                      s.bankSnapshot!.upiId!.isNotEmpty)
                    _bankRow('UPI ID', s.bankSnapshot!.upiId!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required Color color,
    required String label,
    required String date,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirst ? 0 : 12,
        bottom: isLast ? 0 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
