import '../config/api_config.dart';
import '../models/provider_profile.dart';
import 'api_client.dart';

class ProviderApiService {
  Future<ProviderProfile> createProfile({
    required List<String> skills,
    required List<Map<String, dynamic>> availability,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'skills': skills,
      'availability': availability,
    };
    if (address != null && address.isNotEmpty) {
      body['location'] = {'address': address};
    }

    final response = await ApiClient.post(ApiConfig.profile, body);
    final data = response['data'];
    if (data['provider'] != null) return ProviderProfile.fromJson(data['provider']);
    return ProviderProfile.fromJson(data);
  }

  Future<ProviderProfile> getProfile() async {
    final response = await ApiClient.get(ApiConfig.profile);
    final data = response['data'];
    if (data['provider'] != null) return ProviderProfile.fromJson(data['provider']);
    return ProviderProfile.fromJson(data);
  }

  Future<ProviderProfile> updateProfile(Map<String, dynamic> updates) async {
    final response = await ApiClient.put(ApiConfig.profile, updates);
    final data = response['data'];
    if (data['provider'] != null) return ProviderProfile.fromJson(data['provider']);
    return ProviderProfile.fromJson(data);
  }
}
