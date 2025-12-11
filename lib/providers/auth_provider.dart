import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier{
  final AuthService _authService = const AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? get accessToken => _accessToken;

  bool get isLoggedIn => _accessToken != null;


  Future<bool> login(String email, String password) async {
    try {
      final token = await _authService.login(email, password);

      _accessToken = token;
      await _storage.write(key: 'accessToken', value: token);

      notifyListeners();
      return true;
    } catch(e) {
      debugPrint('로그인 오류: $e');
      return false;
    }
  }

  Future<bool> signup(String email, String password, String nickname, String verificationToken,) async{
    try{
      await _authService.signup(email, password, nickname, verificationToken);
      return true;
    }catch (e) {
      debugPrint('회원가입 오류: $e');
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    try{
      final token = await _authService.reissueToken();

      _accessToken = token;
      await _storage.write(key: 'accessToken', value: token);
    }catch(e) {
      debugPrint('로그인 오류: $e');
      _accessToken = null;
    }

    notifyListeners();
  }

  Future<void> logout() async{
    if (_accessToken != null) {
      try {
        await _authService.logout(_accessToken!);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('클라이언트 로그아웃은 성공, 서버 RT 무효화 요청 실패: $e');
        }
      }
    }
    try {
      await _storage.deleteAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SecureStorage 삭제 중 오류 발생: $e');
      }
    }
    _accessToken = null;
    notifyListeners();
  }
}