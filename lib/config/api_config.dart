/// API Configuration — Base URL and endpoint constants
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Provider Profile
  static const String profile = '/worker/profile';

  // Worker Bookings
  static const String bookings = '/worker/bookings';
  static String acceptBooking(String id) => '/worker/bookings/$id/accept';
  static String rejectBooking(String id) => '/worker/bookings/$id/reject';
  static String completeBooking(String id) => '/worker/bookings/$id/complete';
}
