import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/profile_provider.dart';
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
          children: [_buildDashboardTab(), _buildJobsTab(), _buildProfileTab()],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_history_rounded),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
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
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildOnlinePanel(),
              const SizedBox(height: 18),
              _buildStatCards(),
              const SizedBox(height: 24),
              _sectionTitle('New requests'),
              const SizedBox(height: 12),
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
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.textPrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  (auth.user?.name ?? 'W')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Partner dashboard',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    auth.user?.name ?? 'Worker',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlinePanel() {
    return Consumer2<ProfileProvider, BookingProvider>(
      builder: (_, profileProvider, bookings, __) {
        final isOnline = profileProvider.profile?.isAvailable ?? false;
        final todayEarnings = bookings.bookings.fold<double>(0, (sum, booking) {
          return booking.status == 'completed' ? sum + booking.price : sum;
        });
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.textPrimary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today earnings',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs ${todayEarnings.toInt()}',
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isOnline ? AppTheme.success : AppTheme.textMuted)
                                .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppTheme.success
                                  : AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isOnline
                                  ? AppTheme.success
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _panelMetric(
                      Icons.near_me_rounded,
                      '${bookings.activeCount}',
                      'active',
                    ),
                    const SizedBox(width: 12),
                    _panelMetric(
                      Icons.timer_rounded,
                      '${bookings.pendingCount}',
                      'waiting',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _panelMetric(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryLight, size: 22),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
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
            Expanded(
              child: _statCard(
                'Pending',
                bp.pendingCount,
                AppTheme.warning,
                Icons.hourglass_top_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Active',
                bp.activeCount,
                AppTheme.accepted,
                Icons.play_circle_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Done',
                bp.completedCount,
                AppTheme.success,
                Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return Consumer<BookingProvider>(
      builder: (_, bp, __) {
        if (bp.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        final pending = bp.pendingBookings;
        if (pending.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(36),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    color: AppTheme.textMuted,
                    size: 46,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No pending requests',
                    style: GoogleFonts.inter(color: AppTheme.textMuted),
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
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _detailRow(
                  Icons.calendar_today_rounded,
                  booking.date.split('T')[0],
                  Icons.access_time_rounded,
                  booking.slot,
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.currency_rupee_rounded,
                  'Rs ${booking.price.toInt()}',
                  Icons.near_me_rounded,
                  'Nearby job',
                ),
              ],
            ),
          ),
          if (booking.status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(booking.id, 'reject'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(booking.id, 'accept'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.textPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (booking.status == 'accepted') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(booking.id, 'complete'),
                icon: const Icon(Icons.task_alt_rounded, size: 18),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData leftIcon,
    String left,
    IconData rightIcon,
    String right,
  ) {
    return Row(
      children: [
        Icon(leftIcon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            left,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(rightIcon, size: 15, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(String id, String action) async {
    final bp = context.read<BookingProvider>();
    bool success = false;
    switch (action) {
      case 'accept':
        success = await bp.acceptBooking(id);
        break;
      case 'reject':
        success = await bp.rejectBooking(id);
        break;
      case 'complete':
        success = await bp.completeBooking(id);
        break;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? bp.successMessage ?? 'Action completed'
              : bp.error ?? 'Action failed',
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  Widget _buildJobsTab() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            child: Text(
              'All jobs',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Consumer<BookingProvider>(
              builder: (_, bp, __) {
                if (bp.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }
                if (bp.bookings.isEmpty) {
                  return Center(
                    child: Text(
                      'No jobs yet',
                      style: GoogleFonts.inter(color: AppTheme.textMuted),
                    ),
                  );
                }
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
        padding: const EdgeInsets.all(20),
        child: Consumer2<AuthProvider, ProfileProvider>(
          builder: (_, auth, profProvider, __) {
            final profile = profProvider.profile;
            return Column(
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      (auth.user?.name ?? 'W')[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  auth.user?.name ?? 'Worker',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  auth.user?.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                if (profile != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _profileStat(
                          profile.rating.toStringAsFixed(1),
                          'Rating',
                          Icons.star_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _profileStat(
                          '${profile.totalJobs}',
                          'Jobs',
                          Icons.work_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _profileStat(
                          profile.isVerified ? 'Yes' : 'No',
                          'Verified',
                          Icons.verified_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skills',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.skills.map((s) {
                            return Chip(
                              label: Text(
                                s,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              backgroundColor: AppTheme.bgCardLight,
                              side: BorderSide(
                                color: AppTheme.primary.withValues(alpha: 0.24),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                GlassCard(
                  onTap: () async {
                    final nav = Navigator.of(context);
                    await auth.logout();
                    nav.pushReplacementNamed('/login');
                  },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppTheme.error,
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.error,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _profileStat(String value, String label, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
