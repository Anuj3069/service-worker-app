import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/booking.dart';

/// Full-screen map that shows the worker's live position and the customer's
/// destination. Uses OpenStreetMap tiles via flutter_map (no API key needed).
class MapTrackingScreen extends StatefulWidget {
  final Booking booking;

  const MapTrackingScreen({super.key, required this.booking});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final MapController _mapController = MapController();

  LatLng? _workerPos;
  StreamSubscription<Position>? _positionSub;
  bool _isLoadingLocation = true;
  String? _locationError;

  // Distance to customer in metres (null = not calculated yet)
  double? _distanceMetres;

  @override
  void initState() {
    super.initState();
    _initLiveLocation();
  }

  Future<void> _initLiveLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationError = 'Location permission denied.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location permission permanently denied. Enable it in settings.';
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Location services are disabled.';
        });
        return;
      }

      // Get initial position quickly
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _workerPos = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
          _updateDistance();
        });
        _fitBounds();
      }

      // Subscribe to live updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // update every 5 m moved
        ),
      ).listen((p) {
        if (mounted) {
          setState(() {
            _workerPos = LatLng(p.latitude, p.longitude);
            _updateDistance();
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Could not get location: $e';
        });
      }
    }
  }

  void _updateDistance() {
    final wPos = _workerPos;
    final cLat = widget.booking.customerLatitude;
    final cLng = widget.booking.customerLongitude;
    if (wPos == null || cLat == null || cLng == null) return;
    _distanceMetres = Geolocator.distanceBetween(
      wPos.latitude, wPos.longitude,
      cLat, cLng,
    );
  }

  void _fitBounds() {
    final wPos = _workerPos;
    final cLat = widget.booking.customerLatitude;
    final cLng = widget.booking.customerLongitude;
    if (wPos == null || cLat == null || cLng == null) return;

    final bounds = LatLngBounds(
      LatLng(
        wPos.latitude < cLat ? wPos.latitude : cLat,
        wPos.longitude < cLng ? wPos.longitude : cLng,
      ),
      LatLng(
        wPos.latitude > cLat ? wPos.latitude : cLat,
        wPos.longitude > cLng ? wPos.longitude : cLng,
      ),
    );

    // Delay slightly to ensure map is rendered
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
        );
      }
    });
  }

  Future<void> _openExternalMaps() async {
    final cLat = widget.booking.customerLatitude;
    final cLng = widget.booking.customerLongitude;
    if (cLat == null || cLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer location not available')),
      );
      return;
    }
    final label = Uri.encodeComponent(widget.booking.customerName);
    // Try Google Maps, fallback to geo URI
    final googleUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$cLat,$cLng');
    final geoUri = Uri.parse('geo:$cLat,$cLng?q=$cLat,$cLng($label)');

    if (await canLaunchUrl(googleUri)) {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No maps app found on this device')),
        );
      }
    }
  }

  String _formatDistance(double metres) {
    if (metres >= 1000) {
      return '${(metres / 1000).toStringAsFixed(1)} km away';
    }
    return '${metres.toInt()} m away';
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cLat = widget.booking.customerLatitude;
    final cLng = widget.booking.customerLongitude;
    final hasCustomerLocation = cLat != null && cLng != null;
    final customerLatLng = hasCustomerLocation ? LatLng(cLat, cLng) : null;

    // Centre map: worker pos > customer pos > default India centre
    final initialCentre = _workerPos ?? customerLatLng ?? const LatLng(20.5937, 78.9629);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Navigate to Customer',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            widget.booking.customerName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance pill
                    if (_distanceMetres != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accepted.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.accepted.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          _formatDistance(_distanceMetres!),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accepted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Map ──────────────────────────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    if (_locationError != null)
                      // Error state
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_off_rounded,
                                  color: AppTheme.error, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                _locationError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Map view
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: initialCentre,
                          initialZoom: 14,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          // OpenStreetMap tiles (no API key)
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.serviceapp.worker_app',
                          ),

                          // Straight-line route between worker & customer
                          if (_workerPos != null && customerLatLng != null)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [_workerPos!, customerLatLng],
                                  color: AppTheme.accepted,
                                  strokeWidth: 3,
                                  pattern: StrokePattern.dashed(
                                      segments: [12, 6]),
                                ),
                              ],
                            ),

                          // Markers
                          MarkerLayer(
                            markers: [
                              // Worker marker (blue)
                              if (_workerPos != null)
                                Marker(
                                  point: _workerPos!,
                                  width: 48,
                                  height: 48,
                                  child: _WorkerMarker(),
                                ),
                              // Customer marker (orange)
                              if (customerLatLng != null)
                                Marker(
                                  point: customerLatLng,
                                  width: 48,
                                  height: 58,
                                  child: _CustomerMarker(
                                      name: widget.booking.customerName),
                                ),
                            ],
                          ),
                        ],
                      ),

                    // Loading overlay
                    if (_isLoadingLocation)
                      Container(
                        color: Colors.black38,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      ),

                    // ── Fit-bounds FAB ──────────────────────────────
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _MapFab(
                        icon: Icons.fit_screen_rounded,
                        tooltip: 'Fit both markers',
                        onTap: _fitBounds,
                      ),
                    ),

                    // ── Centre on worker FAB ────────────────────────
                    Positioned(
                      top: 68,
                      right: 12,
                      child: _MapFab(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Centre on me',
                        onTap: () {
                          if (_workerPos != null) {
                            _mapController.move(_workerPos!, 16);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Action Bar ─────────────────────────────────────
            Container(
              color: AppTheme.bgCard,
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer address (if available)
                  if (widget.booking.customerAddress != null) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.booking.customerAddress!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // "Open in Google Maps" button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: hasCustomerLocation
                          ? _openExternalMaps
                          : null,
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(
                        'Open in Google Maps',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),

                  if (!hasCustomerLocation) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Customer location is not available for this booking.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom map marker widgets ─────────────────────────────────────────────────

class _WorkerMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.accepted,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accepted.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 22),
    );
  }
}

class _CustomerMarker extends StatelessWidget {
  final String name;
  const _CustomerMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            name.length > 10 ? '${name.substring(0, 10)}…' : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
        ),
      ],
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 22),
        ),
      ),
    );
  }
}
