import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../widgets/gradient_button.dart';

/// Full-screen "new job request" prompt, pushed automatically (like an
/// incoming-call screen) whenever a booking is assigned/broadcast to this
/// worker over the socket, or when the worker taps the push notification.
class JobRequestScreen extends StatefulWidget {
  final Booking booking;
  final bool isInstant;
  final String? expiresAt;

  const JobRequestScreen({
    super.key,
    required this.booking,
    this.isInstant = false,
    this.expiresAt,
  });

  @override
  State<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends State<JobRequestScreen> {
  double? _distanceKm;
  bool _isActing = false;
  bool _leaving = false;
  BookingProvider? _bookingProvider;

  @override
  void initState() {
    super.initState();
    _resolveDistance();
    if (widget.isInstant) {
      _bookingProvider = context.read<BookingProvider>();
      _bookingProvider!.addListener(_handleBookingProviderChange);
    }
  }

  @override
  void dispose() {
    _bookingProvider?.removeListener(_handleBookingProviderChange);
    super.dispose();
  }

  /// If this instant request gets taken by another worker, or expires and
  /// gets swept up by the periodic cleanup, close this screen automatically.
  void _handleBookingProviderChange() {
    if (_leaving || !mounted) return;
    final stillPending = _bookingProvider!.instantRequests.any(
      (r) => r['bookingId']?.toString() == widget.booking.id,
    );
    if (!stillPending) {
      _leaving = true;
      Navigator.of(context).pop();
    }
  }

  Future<void> _resolveDistance() async {
    final booking = widget.booking;
    final lat = booking.customerLatitude;
    final lng = booking.customerLongitude;
    if (lat == null || lng == null) return;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );
      if (!mounted) return;
      setState(() => _distanceKm = meters / 1000);
    } catch (_) {
      // Distance is a nice-to-have; ignore failures (permission/timeout/etc).
    }
  }

  String get _timeRange {
    final parts = widget.booking.slot.split('-');
    if (parts.length != 2) return widget.booking.slot;
    final start = _to12Hour(parts[0]);
    final end = _to12Hour(parts[1]);
    if (start == null || end == null) return widget.booking.slot;
    return '$start - $end';
  }

  String? _to12Hour(String hhmm) {
    final segments = hhmm.trim().split(':');
    if (segments.length != 2) return null;
    final hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    final time = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(time);
  }

  String get _durationLabel {
    final booking = widget.booking;
    if (booking.durationHours != null) {
      return '${booking.durationHours} Hours';
    }
    if (booking.durationType != null) {
      return booking.durationType == 'FULL_DAY' ? 'Full Day' : 'Half Day';
    }
    final parts = booking.slot.split('-');
    if (parts.length == 2) {
      final start = parts[0].split(':').map(int.tryParse).toList();
      final end = parts[1].split(':').map(int.tryParse).toList();
      if (start.length == 2 &&
          end.length == 2 &&
          start[0] != null &&
          end[0] != null) {
        final startMinutes = start[0]! * 60 + (start[1] ?? 0);
        final endMinutes = end[0]! * 60 + (end[1] ?? 0);
        final diffHours = (endMinutes - startMinutes) / 60;
        if (diffHours > 0) {
          return diffHours == diffHours.roundToDouble()
              ? '${diffHours.toInt()} Hours'
              : '${diffHours.toStringAsFixed(1)} Hours';
        }
      }
    }
    return '—';
  }

  String get _badgeLabel {
    if (widget.isInstant) return 'Instant Job';
    return widget.booking.isMonthBooking ? 'Monthly Job' : 'Nearby Job';
  }

  Color get _badgeColor =>
      widget.isInstant ? AppTheme.warning : AppTheme.success;

  String get _dateLabel {
    try {
      final date = DateTime.parse(widget.booking.date);
      return DateFormat('d MMM y').format(date);
    } catch (_) {
      return widget.booking.date.split('T').first;
    }
  }

  Future<void> _respond(bool accept) async {
    if (_isActing || _leaving) return;
    setState(() => _isActing = true);
    final bp = context.read<BookingProvider>();
    final success = accept
        ? await bp.acceptBooking(widget.booking.id, isInstant: widget.isInstant)
        : await bp.rejectBooking(widget.booking.id, isInstant: widget.isInstant);
    if (!mounted) return;
    if (success) {
      _leaving = true;
      Navigator.of(context).pop();
    } else {
      setState(() => _isActing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bp.error ?? 'Something went wrong. Please try again.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          booking.serviceName,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _badgeLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.isInstant && widget.expiresAt != null) ...[
                    const SizedBox(height: 12),
                    _ExpiryCountdown(expiresAt: widget.expiresAt!),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          booking.customerAddress ?? 'Address unavailable',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (_distanceKm != null)
                        Text(
                          '${_distanceKm!.toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFEDF0F5)),
                  const SizedBox(height: 6),
                  _detailRow(Icons.calendar_today_rounded, 'Date', _dateLabel),
                  _detailRow(Icons.access_time_rounded, 'Time', _timeRange),
                  _detailRow(
                    Icons.hourglass_bottom_rounded,
                    'Duration',
                    _durationLabel,
                  ),
                  _detailRow(
                    Icons.person_outline_rounded,
                    'Customer',
                    booking.customerName,
                  ),
                  _detailRow(
                    Icons.currency_rupee_rounded,
                    'Amount',
                    '₹${booking.price.toInt()}',
                    valueColor: AppTheme.primary,
                    valueWeight: FontWeight.w800,
                  ),
                ],
              ),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        8,
        14,
      ),
      color: AppTheme.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Spacer(),
          const Icon(
            Icons.notifications_none_rounded,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    FontWeight valueWeight = FontWeight.w700,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: valueWeight,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GradientButton(
              text: 'Accept Now',
              isLoading: _isActing,
              onPressed: () => _respond(true),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isActing ? null : () => _respond(false),
            child: Text(
              'Reject',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a live "Expires in mm:ss" countdown for instant requests. Purely
/// cosmetic — actual expiry/removal is driven by [BookingProvider], this
/// widget just reflects the remaining time visually.
class _ExpiryCountdown extends StatefulWidget {
  final String expiresAt;

  const _ExpiryCountdown({required this.expiresAt});

  @override
  State<_ExpiryCountdown> createState() => _ExpiryCountdownState();
}

class _ExpiryCountdownState extends State<_ExpiryCountdown> {
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
      final expiry = DateTime.parse(widget.expiresAt);
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
    final formatted =
        '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    final isUrgent = _secondsRemaining < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: (isUrgent ? AppTheme.error : AppTheme.warning)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            color: isUrgent ? AppTheme.error : AppTheme.warning,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _secondsRemaining > 0 ? 'Expires in $formatted' : 'Expired',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isUrgent ? AppTheme.error : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}
