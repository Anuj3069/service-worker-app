import '../config/api_config.dart';
import '../models/settlement.dart';
import 'api_client.dart';

class SettlementApiService {
  /// GET /worker/profile/bank-details
  Future<Map<String, dynamic>?> getBankDetails() async {
    final response = await ApiClient.get(ApiConfig.bankDetails);
    return response['data']?['bankDetails'];
  }

  /// PUT /worker/profile/bank-details
  Future<Map<String, dynamic>> saveBankDetails(Map<String, dynamic> data) async {
    final response = await ApiClient.put(ApiConfig.bankDetails, data);
    return response['data']?['bankDetails'] ?? {};
  }

  /// POST /worker/settlement/request
  Future<Settlement> requestSettlement() async {
    final response = await ApiClient.post(ApiConfig.settlementRequest, {});
    return Settlement.fromJson(response['data']['settlement']);
  }

  /// GET /worker/settlement?page=&limit=
  Future<Map<String, dynamic>> getSettlements({int page = 1, int limit = 20}) async {
    final response = await ApiClient.get(
      '${ApiConfig.settlements}?page=$page&limit=$limit&sort=-createdAt',
    );
    return response['data'] ?? {};
  }

  /// GET /worker/settlement/:id
  Future<Settlement> getSettlementById(String id) async {
    final response = await ApiClient.get(ApiConfig.settlementDetail(id));
    return Settlement.fromJson(response['data']['settlement']);
  }
}
