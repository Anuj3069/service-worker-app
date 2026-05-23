import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/profile_provider.dart';
import '../models/booking.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/connection_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Timer? _expiryCleanupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchAllBookings();
      context.read<ProfileProvider>().fetchProfile();
    });

    // Periodically clean up expired instant requests
    _expiryCleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<BookingProvider>().cleanupExpiredRequests();
      }
    });
  }

  @override
  void dispose() {
    _expiryCleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            // Connection status banner (Redis socket state)
            SafeArea(
              bottom: false,
              child: Consumer<BookingProvider>(
                builder: (_, bp, __) => ConnectionBanner(
                  isConnected: bp.isSocketConnected,
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardTab(),
                  _buildJobsTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppTheme.bgCard, border: Border(top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            const BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: 'Jobs'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: () => context.read<BookingProvider>().fetchAllBookings(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildInstantAlerts(),
              _buildScheduledNotifications(),
              _buildStatCards(),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Pending Requests', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ),
              const SizedBox(height: 14),
              _buildPendingList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer2<AuthProvider, BookingProvider>(
      builder: (_, auth, bp, __) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text((auth.user?.name ?? 'W')[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Welcome back,', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                Text(auth.user?.name ?? 'Worker', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              ]),
            ),
            // Live indicator (Redis socket connection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (bp.isSocketConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (bp.isSocketConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.4),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: bp.isSocketConnected ? AppTheme.success : AppTheme.error,
                    boxShadow: [
                      BoxShadow(
                        color: (bp.isSocketConnected ? AppTheme.success : AppTheme.error).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  bp.isSocketConnected ? 'Live' : 'Offline',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bp.isSocketConnected ? AppTheme.success : AppTheme.error,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            Consumer<ProfileProvider>(
              builder: (_, profile, __) {
                final isOnline = profile.profile?.isAvailable ?? false;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isOnline ? AppTheme.success : AppTheme.textMuted).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: (isOnline ? AppTheme.success : AppTheme.textMuted).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? AppTheme.success : AppTheme.textMuted)),
                    const SizedBox(width: 6),
                    Text(isOnline ? 'Online' : 'Offline', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isOnline ? AppTheme.success : AppTheme.textMuted)),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(child: _statCard('Pending', bp.pendingCount, AppTheme.warning, Icons.hourglass_top_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Active', bp.activeCount, AppTheme.accepted, Icons.play_circle_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Done', bp.completedCount, AppTheme.success, Icons.check_circle_rounded)),
          ],
        ),
      ),
    );
  }

  /// Builds the instant booking request alerts with countdown timer.
  /// These come from Redis Pub/Sub → new-booking-request events.
  Widget _buildInstantAlerts() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) {
        if (bp.instantRequests.isEmpty) return const SizedBox.shrink();

        return Column(
          children: bp.instantRequests.map((req) {
            final serviceDetails = req['service'] is Map ? req['service'] : null;
            final serviceName = serviceDetails != null ? serviceDetails['name'] : 'Instant Service Request';
            final price = req['price'] ?? 0;
            final bookingId = req['bookingId']?.toString() ?? '';
            final expiresAt = req['expiresAt'];

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFE85D26)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.4),
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
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('INSTANT REQUEST', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1)),
                                const SizedBox(width: 8),
                                // Redis Pub/Sub badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('LIVE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                                ),
                              ],
                            ),
                            Text(serviceName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                      Text('₹${price is num ? price.toInt() : price}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Countdown timer from Redis TTL
                  if (expiresAt != null)
                    _InstantCountdown(expiresAt: expiresAt),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => bp.rejectBooking(bookingId, isInstant: true),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => bp.acceptBooking(bookingId, isInstant: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Accept Quick'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Shows notifications for new scheduled bookings (from Redis Pub/Sub).
  Widget _buildScheduledNotifications() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) {
        final unread = bp.scheduledNotifications.where((n) => n['isRead'] != true).toList();
        if (unread.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accepted.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accepted.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active_rounded, color: AppTheme.accepted, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${unread.length} new scheduled booking${unread.length > 1 ? 's' : ''}',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => bp.clearScheduledNotifications(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accepted,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text('Dismiss', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'New bookings have been assigned to you. Check your pending requests.',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text('$count', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) {
        if (bp.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primary)));
        final pending = bp.pendingBookings;
        if (pending.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Column(children: [
              Icon(Icons.inbox_rounded, color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 12),
              Text('No pending requests', style: GoogleFonts.inter(color: AppTheme.textMuted)),
            ])),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: pending.length,
          itemBuilder: (_, i) => _buildBookingCard(pending[i]),
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(booking.serviceName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textMuted), const SizedBox(width: 6),
            Text(booking.customerName, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 16),
            Text('₹${booking.price.toInt()}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.accent)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textMuted), const SizedBox(width: 6),
            Text(booking.date.split('T')[0], style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 16),
            Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textMuted), const SizedBox(width: 6),
            Text(booking.slot, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          if (booking.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleAction(booking.id, 'reject'),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error, side: const BorderSide(color: AppTheme.error), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(booking.id, 'accept'),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ],
          if (booking.status == 'accepted') ...[
            const SizedBox(height: 16),
            Consumer<BookingProvider>(
              builder: (_, bp, __) {
                final isTrackingThis = bp.isEnRoute && bp.activeTrackingBookingId == booking.id;
                return Column(
                  children: [
                    // Live tracking badge
                    if (isTrackingThis)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.success,
                                boxShadow: [BoxShadow(color: AppTheme.success.withValues(alpha: 0.6), blurRadius: 6)],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Live Tracking Active',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.success),
                            ),
                          ],
                        ),
                      ),
                    // Tracking + Complete buttons row
                    Row(children: [
                      Expanded(
                        child: isTrackingThis
                            ? OutlinedButton.icon(
                                onPressed: () => bp.stopTracking(),
                                icon: const Icon(Icons.stop_rounded, size: 18),
                                label: const Text('Stop'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.warning,
                                  side: const BorderSide(color: AppTheme.warning),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: bp.isEnRoute
                                    ? null // Another booking is being tracked
                                    : () => bp.startTracking(booking.id),
                                icon: const Icon(Icons.navigation_rounded, size: 18),
                                label: const Text('En Route'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accepted,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (isTrackingThis) bp.stopTracking();
                            _handleAction(booking.id, 'complete');
                          },
                          icon: const Icon(Icons.task_alt_rounded, size: 18),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ]),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(String id, String action) async {
    final bp = context.read<BookingProvider>();
    bool success = false;
    switch (action) {
      case 'accept': success = await bp.acceptBooking(id); break;
      case 'reject': success = await bp.rejectBooking(id); break;
      case 'complete': success = await bp.completeBooking(id); break;
    }
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.successMessage ?? 'Action completed'), backgroundColor: AppTheme.success));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bp.error ?? 'Action failed'), backgroundColor: AppTheme.error));
    }
  }

  Widget _buildJobsTab() {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('All Jobs', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (_, bp, __) {
                if (bp.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                if (bp.bookings.isEmpty) return Center(child: Text('No jobs yet', style: GoogleFonts.inter(color: AppTheme.textMuted)));
                return RefreshIndicator(
                  onRefresh: () => bp.fetchAllBookings(),
                  color: AppTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: bp.bookings.length,
                    itemBuilder: (_, i) => _buildBookingCard(bp.bookings[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Consumer2<AuthProvider, ProfileProvider>(
          builder: (_, auth, profProvider, __) {
            final profile = profProvider.profile;
            return Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 24)]),
                  child: Center(child: Text((auth.user?.name ?? 'W')[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white))),
                ),
                const SizedBox(height: 20),
                Text(auth.user?.name ?? 'Worker', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text(auth.user?.email ?? '', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted)),
                const SizedBox(height: 24),
                if (profile != null) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _profileStat('⭐ ${profile.rating.toStringAsFixed(1)}', 'Rating'),
                    const SizedBox(width: 32),
                    _profileStat('${profile.totalJobs}', 'Jobs'),
                    const SizedBox(width: 32),
                    _profileStat(profile.isVerified ? '✓' : '✗', 'Verified'),
                  ]),
                  const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skills', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, runSpacing: 8, children: profile.skills.map((s) => Chip(
                          label: Text(s, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.accent)),
                          backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                          side: BorderSide(color: AppTheme.accent.withValues(alpha: 0.3)),
                        )).toList()),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GlassCard(
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await auth.logout();
                    nav.pushReplacementNamed('/login');
                  },
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(children: [
                    const Icon(Icons.logout_rounded, color: AppTheme.error, size: 22),
                    const SizedBox(width: 16),
                    Text('Logout', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.error)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileStat(String value, String label) {
    return Column(children: [
      Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted)),
    ]);
  }
}

/// A countdown widget that shows remaining time until Redis TTL expiry.
/// Updates every second to show a live countdown for instant booking requests.
class _InstantCountdown extends StatefulWidget {
  final dynamic expiresAt;

  const _InstantCountdown({required this.expiresAt});

  @override
  State<_InstantCountdown> createState() => _InstantCountdownState();
}

class _InstantCountdownState extends State<_InstantCountdown> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _calculateRemaining() {
    try {
      final expiry = DateTime.parse(widget.expiresAt.toString());
      final diff = expiry.difference(DateTime.now());
      _secondsRemaining = diff.inSeconds > 0 ? diff.inSeconds : 0;
    } catch (_) {
      _secondsRemaining = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;
    final formatted = '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    final isUrgent = _secondsRemaining < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            color: isUrgent ? Colors.yellow : Colors.white.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _secondsRemaining > 0
                ? 'Expires in $formatted'
                : 'Expired',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isUrgent ? Colors.yellow : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
