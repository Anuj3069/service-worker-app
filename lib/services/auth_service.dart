import '../config/api_config.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthService {
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = <String, String>{
      'name': name,
      'email': email,
      'password': password,
      'role': 'worker',
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;

    final response = await ApiClient.post(ApiConfig.register, body, auth: false);
    final authResponse = AuthResponse.fromJson(response['data']);
    await ApiClient.saveTokens(authResponse.tokens.accessToken, authResponse.tokens.refreshToken);
    await ApiClient.saveUserData(authResponse.user.toJson());
    return authResponse;
  }

  Future<AuthResponse> login({required String email, required String password}) async {
    final response = await ApiClient.post(ApiConfig.login, {'email': email, 'password': password}, auth: false);
    final authResponse = AuthResponse.fromJson(response['data']);
    await ApiClient.saveTokens(authResponse.tokens.accessToken, authResponse.tokens.refreshToken);
    await ApiClient.saveUserData(authResponse.user.toJson());
    return authResponse;
  }

  Future<void> logout() async => await ApiClient.clearAll();

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return await ApiClient.post(ApiConfig.forgotPassword, {'email': email}, auth: false);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
  }) async {
    return await ApiClient.post(
      ApiConfig.resetPassword,
      {'token': token, 'password': password},
      auth: false,
    );
  }
}
