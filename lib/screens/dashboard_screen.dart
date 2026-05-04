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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchAllBookings();
      context.read<ProfileProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildDashboardTab(),
            _buildJobsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppTheme.bgCard, border: Border(top: BorderSide(color: AppTheme.primary.withValues(alpha: 0.2)))),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.work_rounded), label: 'Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SafeArea(
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
              _buildInstantAlert(),
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
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => Padding(
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
            Consumer<ProfileProvider>(
              builder: (_, profile, __) {
                final isOnline = profile.profile?.isAvailable ?? false;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildInstantAlert() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) {
        if (bp.instantRequests.isEmpty) return const SizedBox.shrink();
        
        final req = bp.instantRequests.first;
        final serviceDetails = req['service'] is Map ? req['service'] : null;
        final serviceName = serviceDetails != null ? serviceDetails['name'] : 'Instant Service Request';
        final price = req['price'] ?? 0;
        final bookingId = req['bookingId'];

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                        Text('INSTANT REQUEST', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1)),
                        Text(serviceName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                  Text('₹${price.toInt()}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 20),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(booking.id, 'complete'),
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
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
