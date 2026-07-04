/// API Configuration — Base URL and endpoint constants
class ApiConfig {
  // Production backend URL (deployed on Render)
  static const String baseUrl = 'https://service-app-rduc.onrender.com/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Provider Profile
  static const String profile = '/worker/profile';
  static const String kyc = '/worker/profile/kyc';

  // Worker Bookings
  static const String bookings = '/worker/bookings';
  static String acceptBooking(String id) => '/worker/bookings/$id/accept';
  static String rejectBooking(String id) => '/worker/bookings/$id/reject';
  static String completeBooking(String id) => '/worker/bookings/$id/complete';
  static String confirmCash(String id) => '/worker/bookings/$id/confirm-cash';
  static String bookingById(String id) => '/worker/bookings/$id';
  static String bookingChat(String id) => '/worker/bookings/$id/chat';

  // Support
  static String createSupportTicket(String bookingId) =>
      '/worker/bookings/$bookingId/support';
  static String getSupportTicket(String bookingId) =>
      '/worker/bookings/$bookingId/support';
  static String supportMessages(String ticketId) =>
      '/worker/support/$ticketId/messages';

  // Bank Details
  static const String bankDetails = '/worker/profile/bank-details';

  // Settlements
  static const String settlementRequest = '/worker/settlement/request';
  static const String settlements = '/worker/settlement';
  static String settlementDetail(String id) => '/worker/settlement/$id';

  // Wallet (cash-commission ledger)
  static const String wallet = '/worker/wallet';
}
