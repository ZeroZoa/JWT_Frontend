import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthService {

  const AuthService();

  Map<String, String> _getNoAuthHeaders() {
    return {'Content-Type': 'application/json'};
  }

  Future<String> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.login}');
    try {
      final response = await http.post(
        url,
        headers: _getNoAuthHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return responseData['accessToken'];
      } else {
        throw Exception('로그인 실패: ${response.body}');
      }
    } catch (e) {
      throw Exception('로그인 중 오류 발생: $e');
    }
  }

  Future<bool> signup(String email, String password, String nickname,
      String verificationToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.signup}');

    try {
      final response = await http.post(
        url,
        headers: _getNoAuthHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname,
          'verificationToken': verificationToken
        }),
      );
      if (response.statusCode == 201) {
        return true;
      } else {
        throw Exception('회원가입 실패 (서버): ${response.body}');
      }
    } catch (e) {
      throw Exception('회원가입 중 오류 발생: $e');
    }
  }


  Future<String> reissueToken() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.reissue}');

    try {
      final response = await http.post(
        url,
        headers: _getNoAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['accessToken'];
      } else {
        throw Exception('토큰 갱신 실패 (다시 로그인 필요): ${response.body}');
      }
    } catch (e) {
      throw Exception('자동 로그인 중 오류: $e');
    }
  }

  Future<void> logout(String accessToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.logout}');

    try {
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('백엔드 로그아웃 요청 실패 (무시 가능): $e');
      }
    }
  }
}