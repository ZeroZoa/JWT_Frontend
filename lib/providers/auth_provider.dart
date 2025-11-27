import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';


import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier{
  final AuthService _authService = const AuthService();

  String? _accessToken;

  bool get isLoggedIn => _accessToken != null;
  String? get accessToken => _accessToken;

  Future<bool> login(String email, String password) async {
    try {
      final token = await _authService.login(email, password);

      _accessToken = token;
      notifyListeners();
      return true;
    } catch(e) {
      print(e);
      return false;
    }
  }

  Future<bool> signup(String email, String password, String nickname, String verificationToken,) async{
    try{
      await _authService.signup(email, password, nickname, verificationToken);
      return true;
    }catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    try{
      final token = await _authService.reissueToken();

      _accessToken = token;
    }catch(e) {
      print(e);
      _accessToken = null;
    }

    notifyListeners();
  }

  Future<void> logout() async{
    if (_accessToken != null) {
      try {
        await _authService.logout(_accessToken!);
      } catch (e) {
        // 서버에 로그아웃 요청 실패(네트워크 오류 등)는 무시하고 로그만 남깁니다.
        if (kDebugMode) {
          debugPrint('클라이언트 로그아웃은 성공, 서버 RT 무효화 요청 실패: $e');
        }
      }
    }
    _accessToken = null;
    notifyListeners();
  }
}