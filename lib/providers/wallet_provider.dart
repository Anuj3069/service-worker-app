import 'package:flutter/material.dart';
import '../services/wallet_api_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletApiService _api = WalletApiService();

  double _pendingCommissionOwed = 0;
  int _pendingCount = 0;
  bool _isLoading = false;
  String? _error;

  double get pendingCommissionOwed => _pendingCommissionOwed;
  int get pendingCount => _pendingCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getWallet();
      _pendingCommissionOwed = (data['pendingCommissionOwed'] ?? 0).toDouble();
      _pendingCount = data['pendingCount'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
