import 'dart:io';
import 'package:http/http.dart' as http;
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

  Future<ProviderProfile> updateLocation(List<double> coordinates,
      {String? address}) async {
    final body = <String, dynamic>{
      'coordinates': coordinates,
    };
    if (address != null) {
      body['address'] = address;
    }
    final response = await ApiClient.put('${ApiConfig.profile}/location', body);
    final data = response['data'];
    if (data['provider'] != null) return ProviderProfile.fromJson(data['provider']);
    return ProviderProfile.fromJson(data);
  }

  /// Uploads a KYC document (multipart/form-data) to [ApiConfig.kyc].
  Future<ProviderProfile> submitKyc({
    required File file,
    required String documentType,
  }) async {
    final token = await ApiClient.getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kyc}');

    final request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['documentType'] = documentType;
    request.files.add(
      await http.MultipartFile.fromPath(
        'document',
        file.path,
        filename: file.path.split(Platform.pathSeparator).last,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final parsed = ApiClient.parseResponse(response);
    final data = parsed['data'];
    if (data['provider'] != null) return ProviderProfile.fromJson(data['provider']);
    return ProviderProfile.fromJson(data);
  }
}
