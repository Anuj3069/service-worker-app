import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/settlement.dart';
import '../providers/booking_provider.dart';
import '../providers/settlement_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<SettlementProvider>();
      sp.fetchBankDetails();
      sp.fetchSettlements();
    });
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _handleRequestPayout() async {
    setState(() => _isRequesting = true);
    final sp = context.read<SettlementProvider>();
    final settlement = await sp.requestSettlement();

    if (!mounted) return;
    setState(() => _isRequesting = false);

    if (settlement != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Payout of ₹${settlement.totalAmount.toInt()} requested successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sp.error?.replaceAll('Exception: ', '') ??
              'Failed to request payout'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final sp = context.read<SettlementProvider>();
        await Future.wait([
          sp.fetchBankDetails(),
          sp.fetchSettlements(),
        ]);
      },
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Earnings & Payouts',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Manage your settlements',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Total Earnings Card ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<BookingProvider>(
                builder: (_, bp, __) {
                  final totalEarnings = bp.completedBookings.fold<double>(
                    0.0,
                    (sum, b) => sum + b.payout,
                  );
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0968F6), Color(0xFF6C55F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Total Earnings',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '₹${totalEarnings.toInt()}',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bp.completedBookings.length} completed job${bp.completedBookings.length != 1 ? 's' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Bank Details Status + Request Payout ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Consumer<SettlementProvider>(
                builder: (_, sp, __) {
                  return Column(
                    children: [
                      // Bank details card
                      GlassCard(
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                              context, '/bank-details');
                          if (result == true) {
                            sp.fetchBankDetails();
                          }
                        },
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (sp.hasBankDetails
                                        ? AppTheme.success
                                        : AppTheme.warning)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                sp.hasBankDetails
                                    ? Icons.account_balance_rounded
                                    : Icons.warning_amber_rounded,
                                color: sp.hasBankDetails
                                    ? AppTheme.success
                                    : AppTheme.warning,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sp.hasBankDetails
                                        ? '${sp.bankName} • ${sp.maskedAccountNumber}'
                                        : 'Add bank details to receive payouts',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: sp.hasBankDetails
                                          ? AppTheme.textSecondary
                                          : AppTheme.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (sp.hasBankDetails
                                        ? AppTheme.success
                                        : AppTheme.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sp.hasBankDetails ? 'Edit' : 'Add',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: sp.hasBankDetails
                                      ? AppTheme.success
                                      : AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Request Payout Button
                      GradientButton(
                        text: 'Request Payout',
                        icon: Icons.payments_rounded,
                        isLoading: _isRequesting,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        onPressed:
                            sp.hasBankDetails ? _handleRequestPayout : null,
                      ),

                      if (!sp.hasBankDetails)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '⚠️ Please add bank details before requesting payout',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // ── Settlement History ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Settlement History',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Consumer<SettlementProvider>(
              builder: (_, sp, __) {
                if (sp.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                }

                if (sp.settlements.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: AppTheme.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No settlements yet',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete jobs and request your first payout!',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sp.settlements.length,
                  itemBuilder: (_, i) =>
                      _buildSettlementCard(sp.settlements[i]),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard(Settlement s) {
    final color = _statusColor(s.status);

    return GlassCard(
      onTap: () {
        Navigator.pushNamed(context, '/settlement-detail', arguments: s.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${s.totalAmount.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.26)),
                ),
                child: Text(
                  s.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _meta(Icons.work_rounded,
                  '${s.bookingCount} job${s.bookingCount != 1 ? 's' : ''}'),
              const SizedBox(width: 16),
              _meta(Icons.calendar_today_rounded,
                  _formatDate(s.requestedAt)),
              if (s.isSettled && s.settledAt != null) ...[
                const SizedBox(width: 16),
                _meta(Icons.check_circle_rounded,
                    'Paid ${_formatDate(s.settledAt)}'),
              ],
            ],
          ),
          if (s.adminNote != null && s.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (s.isRejected ? AppTheme.error : AppTheme.success)
                    .withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (s.isRejected ? AppTheme.error : AppTheme.success)
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                s.adminNote!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
