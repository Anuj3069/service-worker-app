/// API Configuration — Base URL and endpoint constants
class ApiConfig {
  // Production backend URL (deployed on Render)
  static const String baseUrl = 'https://service-app-rduc.onrender.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Provider Profile
  static const String profile = '/worker/profile';
  static const String kyc = '/worker/profile/kyc';

  // Worker Bookings
  static const String bookings = '/worker/bookings';
  static String acceptBooking(String id) => '/worker/bookings/$id/accept';
  static String rejectBooking(String id) => '/worker/bookings/$id/reject';
  static String completeBooking(String id) => '/worker/bookings/$id/complete';
  static String bookingChat(String id) => '/worker/bookings/$id/chat';
}
