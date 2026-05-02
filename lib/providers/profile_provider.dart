import 'package:flutter/material.dart';
import '../models/provider_profile.dart';
import '../services/provider_api_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProviderApiService _providerApi = ProviderApiService();
  ProviderProfile? _profile;
  bool _isLoading = false;
  String? _error;
  bool _hasProfile = false;

  ProviderProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasProfile => _hasProfile;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _providerApi.getProfile();
      _hasProfile = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // 404 means no profile yet
      if (e.toString().contains('not found') || e.toString().contains('404')) {
        _hasProfile = false;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProfile({
    required List<String> skills,
    required List<Map<String, dynamic>> availability,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _providerApi.createProfile(
        skills: skills, availability: availability, address: address,
      );
      _hasProfile = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _profile = await _providerApi.updateProfile(updates);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
