// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null;
  bool get isAdmin => _user?.role == 'admin';

  final ApiService _apiService = ApiService();

  // --- ĐĂNG NHẬP ---
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(username, password);

      if (result['success'] == true) {
        _token = result['token'];
        _user = UserModel(
          id: result['id'] ?? '',
          name: result['fullName'] ?? username,
          email: username,
          role: result['role'] ?? 'user',
          phone: result['phone'],
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Đăng nhập thất bại';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- ĐĂNG KÝ (Đã Setup riêng cho tài khoản 'admin') ---
  Future<bool> register(
      String name, String email, String password, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🟢 LOGIC MỚI: Kiểm tra nếu tài khoản là 'admin' thì tự động cấp quyền Sếp
      String roleToSend = 'user'; // Mặc định là dân thường
      if (email == 'admin') {
        roleToSend = 'admin'; // Riêng ông 'admin' thì cho làm Sếp
      }

      final success = await _apiService.register(name, email, password, phone,
          role: roleToSend // Gửi quyền này lên Server
          );

      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = "Đăng ký thất bại. Tài khoản hoặc SĐT đã tồn tại.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}
