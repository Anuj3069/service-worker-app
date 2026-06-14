import 'package:flutter/material.dart';
import '../models/settlement.dart';
import '../services/settlement_api_service.dart';

class SettlementProvider extends ChangeNotifier {
  final SettlementApiService _api = SettlementApiService();

  List<Settlement> _settlements = [];
  Map<String, dynamic>? _bankDetails;
  bool _isLoading = false;
  bool _isBankLoading = false;
  String? _error;
  int _total = 0;
  int _page = 1;

  List<Settlement> get settlements => _settlements;
  Map<String, dynamic>? get bankDetails => _bankDetails;
  bool get isLoading => _isLoading;
  bool get isBankLoading => _isBankLoading;
  String? get error => _error;
  int get total => _total;
  int get page => _page;
  bool get hasBankDetails =>
      _bankDetails != null && _bankDetails!['accountNumber'] != null;

  /// Masked account number for display (e.g. ****9012)
  String get maskedAccountNumber {
    final acc = _bankDetails?['accountNumber'] as String?;
    if (acc == null || acc.length < 4) return acc ?? '';
    return '****${acc.substring(acc.length - 4)}';
  }

  String get bankName => _bankDetails?['bankName'] ?? '';

  // ── Bank Details ──────────────────────────────────────────

  Future<void> fetchBankDetails() async {
    _isBankLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bankDetails = await _api.getBankDetails();
      _isBankLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isBankLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBankDetails(Map<String, dynamic> data) async {
    _isBankLoading = true;
    _error = null;
    notifyListeners();
    try {
      _bankDetails = await _api.saveBankDetails(data);
      _isBankLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isBankLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Settlement Requests ───────────────────────────────────

  Future<Settlement?> requestSettlement() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final settlement = await _api.requestSettlement();
      // Prepend to list
      _settlements.insert(0, settlement);
      _total++;
      _isLoading = false;
      notifyListeners();
      return settlement;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchSettlements({int page = 1}) async {
    _isLoading = true;
    _error = null;
    _page = page;
    notifyListeners();
    try {
      final data = await _api.getSettlements(page: page);
      final items = (data['items'] as List? ?? []);
      _settlements = items.map((json) => Settlement.fromJson(json)).toList();
      _total = data['total'] ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Settlement?> fetchSettlementDetail(String id) async {
    try {
      return await _api.getSettlementById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
