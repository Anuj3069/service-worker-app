import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/booking.dart';
import '../services/booking_api_service.dart';
import '../services/socket_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _bookingApi = BookingApiService();
  final SocketService _socketService = SocketService();

  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Track active complete booking operations to prevent race conditions
  final Set<String> _completingBookingIds = {};

  // ── Instant Booking State ──────────────────────────
  final List<Map<String, dynamic>> _instantRequests = [];

  // ── Real-time notification state ───────────────────
  bool _isSocketConnected = false;
  bool _refreshOnReconnect = false;
  List<Map<String, dynamic>> _scheduledNotifications = [];

  StreamSubscription? _newRequestSub;
  StreamSubscription? _bookingTakenSub;
  StreamSubscription? _bookingCancelledSub;
  StreamSubscription? _newScheduledSub;
  StreamSubscription? _bookingPaidSub;
  StreamSubscription? _connectionSub;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<Map<String, dynamic>> get instantRequests => _instantRequests;
  bool get isSocketConnected => _isSocketConnected;
  List<Map<String, dynamic>> get scheduledNotifications =>
      _scheduledNotifications;
  SocketService get socketService => _socketService;

  List<Booking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();
  List<Booking> get requestedBookings =>
      _bookings.where((b) => b.status == 'requested').toList();
  List<Booking> get acceptedBookings =>
      _bookings.where((b) => b.status == 'accepted').toList();
  List<Booking> get completedBookings =>
      _bookings.where((b) => b.status == 'completed').toList();

  int get pendingCount => pendingBookings.length;
  int get activeCount => acceptedBookings.length;
  int get completedCount => completedBookings.length;
  int get instantRequestCount => _instantRequests.length;

  // ── Live Tracking State ───────────────────────────────
  bool _isEnRoute = false;
  String? _activeTrackingBookingId;
  Timer? _locationUpdateTimer;

  bool get isEnRoute => _isEnRoute;
  String? get activeTrackingBookingId => _activeTrackingBookingId;

  /// Get unread scheduled notification count
  int get unreadScheduledCount =>
      _scheduledNotifications.where((n) => n['isRead'] != true).length;

  /// Initialize socket connection after login
  void connectSocket(String userId) {
    _socketService.connect(userId);
    _listenToSocketEvents();
  }

  /// Disconnect socket on logout
  void disconnectSocket() {
    _newRequestSub?.cancel();
    _bookingTakenSub?.cancel();
    _bookingCancelledSub?.cancel();
    _newScheduledSub?.cancel();
    _bookingPaidSub?.cancel();
    _connectionSub?.cancel();
    _socketService.disconnect();
    _instantRequests.clear();
    _isSocketConnected = false;
    _scheduledNotifications.clear();
    notifyListeners();
  }

  void _listenToSocketEvents() {
    _newRequestSub?.cancel();
    _bookingTakenSub?.cancel();
    _bookingCancelledSub?.cancel();
    _newScheduledSub?.cancel();
    _bookingPaidSub?.cancel();
    _connectionSub?.cancel();

    // ── Connection state tracking ──
    _connectionSub = _socketService.onConnectionStateChanged.listen((
      connected,
    ) {
      if (connected && _refreshOnReconnect) {
        _refreshOnReconnect = false;
        fetchAllBookings();
      }

      _isSocketConnected = connected;
      if (!connected) {
        _refreshOnReconnect = true;
      }
      notifyListeners();
    });

    // ── Instant booking request from customer (via Redis Pub/Sub) ──
    _newRequestSub = _socketService.onNewBookingRequest.listen((data) {
      debugPrint('[Worker BookingProvider] 🚨 new-booking-request: $data');
      // Add new request to the list if not already present
      final bookingId = data['bookingId']?.toString();
      final exists = _instantRequests.any(
        (r) => r['bookingId']?.toString() == bookingId,
      );
      if (!exists) {
        // Add expiry countdown data
        final expiresAt = data['expiresAt'];
        _instantRequests.add({
          ...data,
          'receivedAt': DateTime.now().toIso8601String(),
          'expiresAt': expiresAt,
        });
        notifyListeners();
      }
    });

    // ── Another worker accepted the instant booking ──
    _bookingTakenSub = _socketService.onBookingTaken.listen((data) {
      debugPrint('[Worker BookingProvider] 🔒 booking-taken: $data');
      // Remove from pending requests since another worker got it
      final bookingId = data['bookingId']?.toString();
      _instantRequests.removeWhere(
        (r) => r['bookingId']?.toString() == bookingId,
      );
      notifyListeners();
    });

    // ── New scheduled booking assigned to this worker ──
    _bookingCancelledSub = _socketService.onBookingCancelled.listen((data) {
      debugPrint('[Worker BookingProvider] booking-cancelled: $data');
      final bookingId = data['bookingId']?.toString();
      if (bookingId == null) return;

      _instantRequests.removeWhere(
        (r) => r['bookingId']?.toString() == bookingId,
      );
      _bookings = _bookings.where((b) => b.id != bookingId).toList();
      fetchAllBookings();
      notifyListeners();
    });

    _newScheduledSub = _socketService.onNewScheduledBooking.listen((data) {
      debugPrint('[Worker BookingProvider] 📋 new-scheduled-booking: $data');
      final bookingId = data['bookingId']?.toString();
      if (bookingId == null) return;

      final alreadySeen = _scheduledNotifications.any(
        (notification) =>
            notification['data']?['bookingId']?.toString() == bookingId,
      );
      if (alreadySeen) return;

      _scheduledNotifications.insert(0, {
        'type': 'new_scheduled',
        'title': 'New Booking Request',
        'message': 'You have a new scheduled booking request',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });

      // Keep only last 20 notifications
      if (_scheduledNotifications.length > 20) {
        _scheduledNotifications = _scheduledNotifications.sublist(0, 20);
      }

      // Auto-refresh booking list to show the new booking
      fetchAllBookings();
      notifyListeners();
    });

    _bookingPaidSub = _socketService.onBookingPaid.listen((data) {
      debugPrint('[Worker BookingProvider] booking-paid: $data');
      final bookingId = data['bookingId']?.toString();
      if (bookingId == null) return;

      _bookings = _bookings.map((booking) {
        if (booking.id != bookingId) return booking;
        final json = {
          '_id': booking.id,
          'userId': booking.userId,
          'providerId': booking.providerId,
          'serviceId': booking.serviceDetails ?? booking.serviceId,
          'date': booking.date,
          'slot': booking.slot,
          'status': booking.status,
          'price': booking.price,
          'payout': booking.payout,
          'acceptedAt': booking.acceptedAt,
          'completedAt': booking.completedAt,
          'rejectedAt': booking.rejectedAt,
          'createdAt': booking.createdAt,
          'customerLocation': {
            'coordinates': booking.customerCoordinates,
            'address': booking.customerAddress,
          },
          'paymentStatus': data['paymentStatus'] ?? 'paid',
          'paymentMethod': data['paymentMethod'],
        };
        return Booking.fromJson(json);
      }).toList();

      _scheduledNotifications.insert(0, {
        'type': 'booking_paid',
        'title': 'Payment Received',
        'message': 'Customer payment has been completed',
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });

      fetchAllBookings();
      notifyListeners();
    });
  }

  // ── Live Tracking Methods ─────────────────────────────

  /// Start live tracking for a booking: emit tracking-start,
  /// then emit GPS location every 5 seconds.
  Future<void> startTracking(String bookingId) async {
    if (!_socketService.isConnected) {
      _error = 'Cannot start tracking while offline. Please reconnect first.';
      notifyListeners();
      return;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permission denied';
        notifyListeners();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _error =
          'Location permission permanently denied. Please enable in settings.';
      notifyListeners();
      return;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled. Please enable GPS.';
      notifyListeners();
      return;
    }

    _isEnRoute = true;
    _activeTrackingBookingId = bookingId;
    notifyListeners();

    // Emit tracking-start to notify customer
    _socketService.emitTrackingStart(bookingId);

    // Send initial location immediately
    await _sendCurrentLocation(bookingId);

    // Start periodic location updates every 5 seconds
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _sendCurrentLocation(bookingId),
    );
  }

  /// Stop live tracking and cancel the GPS timer.
  void stopTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isEnRoute = false;
    _activeTrackingBookingId = null;
    notifyListeners();
  }

  /// Read the current GPS position and emit it via socket.
  Future<void> _sendCurrentLocation(String bookingId) async {
    if (!_socketService.isConnected) {
      _error = 'Connection lost. Stopping live tracking.';
      stopTracking();
      notifyListeners();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
      _socketService.emitLocationUpdate(bookingId, [
        position.longitude,
        position.latitude,
      ]);
    } catch (e) {
      debugPrint('[Tracking] GPS read error: $e');
    }
  }

  /// Mark a scheduled notification as read
  void markScheduledNotificationRead(int index) {
    if (index >= 0 && index < _scheduledNotifications.length) {
      _scheduledNotifications[index]['isRead'] = true;
      notifyListeners();
    }
  }

  /// Clear all scheduled notifications
  void clearScheduledNotifications() {
    _scheduledNotifications.clear();
    notifyListeners();
  }

  /// Remove an instant request from the UI (without calling API)
  void dismissInstantRequest(String bookingId) {
    _instantRequests.removeWhere(
      (r) => r['bookingId']?.toString() == bookingId,
    );
    notifyListeners();
  }

  /// Remove expired instant requests
  void cleanupExpiredRequests() {
    final now = DateTime.now();
    _instantRequests.removeWhere((r) {
      final expiresAt = r['expiresAt'];
      if (expiresAt == null) return false;
      try {
        final expiryTime = DateTime.parse(expiresAt);
        return now.isAfter(expiryTime);
      } catch (_) {
        return false;
      }
    });
    notifyListeners();
  }

  Future<void> fetchBookings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _bookingApi.getBookings(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bookings = await _bookingApi.getBookings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptBooking(String id, {bool isInstant = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _bookingApi.acceptBooking(id);
      _successMessage = 'Booking accepted!';
      if (isInstant) {
        dismissInstantRequest(id);
      }
      await fetchAllBookings();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String id, {bool isInstant = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (isInstant) {
        // Just remove it from UI, maybe call API to record rejection if backend supports it
        // For instant bookings, rejecting usually just ignores the broadcast
        dismissInstantRequest(id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        await _bookingApi.rejectBooking(id);
        _successMessage = 'Booking rejected';
        await fetchAllBookings();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeBooking(String id, String otp) async {
    if (_completingBookingIds.contains(id)) return false;
    _completingBookingIds.add(id);

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _bookingApi.completeBooking(id, otp);
      _successMessage = 'Job completed! Great work!';
      await fetchAllBookings();
      _completingBookingIds.remove(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _completingBookingIds.remove(id);
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _newRequestSub?.cancel();
    _bookingTakenSub?.cancel();
    _bookingCancelledSub?.cancel();
    _newScheduledSub?.cancel();
    _bookingPaidSub?.cancel();
    _connectionSub?.cancel();
    _locationUpdateTimer?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}
