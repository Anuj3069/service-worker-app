import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_client.dart';

class BookingApiService {
  Future<List<Booking>> getBookings({String? status}) async {
    String endpoint = ApiConfig.bookings;
    if (status != null && status.isNotEmpty) endpoint += '?status=$status';

    final response = await ApiClient.get(endpoint);
    final data = response['data'];
    if (data['bookings'] != null) {
      return (data['bookings'] as List).map((json) => Booking.fromJson(json)).toList();
    }
    return [];
  }

  Future<Booking> acceptBooking(String id) async {
    final response = await ApiClient.put(ApiConfig.acceptBooking(id), {});
    final data = response['data'];
    if (data['booking'] != null) return Booking.fromJson(data['booking']);
    return Booking.fromJson(data);
  }

  Future<Booking> rejectBooking(String id) async {
    final response = await ApiClient.put(ApiConfig.rejectBooking(id), {});
    final data = response['data'];
    if (data['booking'] != null) return Booking.fromJson(data['booking']);
    return Booking.fromJson(data);
  }

  Future<Booking> completeBooking(String id) async {
    final response = await ApiClient.put(ApiConfig.completeBooking(id), {});
    final data = response['data'];
    if (data['booking'] != null) return Booking.fromJson(data['booking']);
    return Booking.fromJson(data);
  }
}
