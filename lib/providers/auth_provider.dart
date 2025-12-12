import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = const AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.login(email, password);
      _isLoggedIn = true;
      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reissueToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');

      if (refreshToken == null) {
        if (kDebugMode) print("AuthProvider: 리프레시 토큰이 없어 갱신 불가");
        await logout();
        return false;
      }

      await _authService.reissueToken(refreshToken);

      _isAuthenticated = true;
      notifyListeners();
      return true;

    } catch (e) {
      if (kDebugMode) print("AuthProvider: 토큰 갱신 실패 ($e) -> 로그아웃 진행");
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    notifyListeners();
  }
}