import '../config/api_config.dart';
import 'api_client.dart';

class WalletApiService {
  Future<Map<String, dynamic>> getWallet() async {
    final response = await ApiClient.get(ApiConfig.wallet);
    return response['data'] as Map<String, dynamic>;
  }
}
