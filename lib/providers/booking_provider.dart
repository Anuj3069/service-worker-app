import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../services/booking_api_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _bookingApi = BookingApiService();
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  List<Booking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();
  List<Booking> get acceptedBookings =>
      _bookings.where((b) => b.status == 'accepted').toList();
  List<Booking> get completedBookings =>
      _bookings.where((b) => b.status == 'completed').toList();

  int get pendingCount => pendingBookings.length;
  int get activeCount => acceptedBookings.length;
  int get completedCount => completedBookings.length;

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

  Future<bool> acceptBooking(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _bookingApi.acceptBooking(id);
      _successMessage = 'Booking accepted!';
      await fetchAllBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectBooking(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _bookingApi.rejectBooking(id);
      _successMessage = 'Booking rejected';
      await fetchAllBookings();
      return true;
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
}
