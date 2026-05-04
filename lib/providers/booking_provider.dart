import 'dart:async';
import 'package:flutter/material.dart';
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

  // ── Instant Booking State ──────────────────────────
  List<Map<String, dynamic>> _instantRequests = [];
  
  StreamSubscription? _newRequestSub;
  StreamSubscription? _bookingTakenSub;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  
  List<Map<String, dynamic>> get instantRequests => _instantRequests;

  List<Booking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();
  List<Booking> get acceptedBookings =>
      _bookings.where((b) => b.status == 'accepted').toList();
  List<Booking> get completedBookings =>
      _bookings.where((b) => b.status == 'completed').toList();

  int get pendingCount => pendingBookings.length;
  int get activeCount => acceptedBookings.length;
  int get completedCount => completedBookings.length;

  /// Initialize socket connection after login
  void connectSocket(String userId) {
    _socketService.connect(userId);
    _listenToSocketEvents();
  }

  /// Disconnect socket on logout
  void disconnectSocket() {
    _newRequestSub?.cancel();
    _bookingTakenSub?.cancel();
    _socketService.disconnect();
    _instantRequests.clear();
  }

  void _listenToSocketEvents() {
    _newRequestSub?.cancel();
    _bookingTakenSub?.cancel();

    _newRequestSub = _socketService.onNewBookingRequest.listen((data) {
      debugPrint('[Worker BookingProvider] new-booking-request: $data');
      // Add new request to the list if not already present
      final exists = _instantRequests.any((r) => r['bookingId'] == data['bookingId']);
      if (!exists) {
        _instantRequests.add(data);
        notifyListeners();
      }
    });

    _bookingTakenSub = _socketService.onBookingTaken.listen((data) {
      debugPrint('[Worker BookingProvider] booking-taken: $data');
      // Remove from pending requests
      _instantRequests.removeWhere((r) => r['bookingId'] == data['bookingId']);
      notifyListeners();
    });
  }

  /// Remove an instant request from the UI (without calling API)
  void dismissInstantRequest(String bookingId) {
    _instantRequests.removeWhere((r) => r['bookingId'] == bookingId);
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
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeBooking(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _bookingApi.completeBooking(id);
      _successMessage = 'Job completed! Great work!';
      await fetchAllBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
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
    _socketService.dispose();
    super.dispose();
  }
}
