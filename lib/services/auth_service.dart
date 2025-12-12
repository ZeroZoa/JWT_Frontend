import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AuthService {

  const AuthService();
  final _storage = const FlutterSecureStorage();

  Map<String, String> _getNoAuthHeaders() {
    return {'Content-Type': 'application/json'};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auth.login}');

    try {
      final response = await http.post(
        url,
        headers: _getNoAuthHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        await _saveTokens(
          accessToken: responseData['accessToken'],
          refreshToken: responseData['refreshToken'],
        );

        if (kDebugMode) print("로그인 성공: $email");

        return responseData;
      }

      // 실패 처리
      else {
        if (kDebugMode) {
          print("로그인 실패 - 상태코드: ${response.statusCode}, 내용: ${utf8.decode(response.bodyBytes)}");
        }

        if (response.statusCode == 400 || response.statusCode == 401) {
          throw Exception('이메일 또는 비밀번호를 확인해주세요.');
        } else if (response.statusCode >= 500) {
          throw Exception('서버 점검 중입니다. 잠시 후 다시 시도해주세요.');
        } else {
          throw Exception('로그인에 실패했습니다. (${response.statusCode})');
        }
      }
    } catch (e) {
      if (kDebugMode) print("로그인 함수 에러: $e");
      if (e is Exception) rethrow;
      throw Exception('네트워크 연결 상태를 확인해주세요.');
    }
  }

  Future<void> reissueToken(String refreshToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auth.reissue}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));

        // 토큰 저장 (앞서 냅두자고 했던 헬퍼 함수 활용)
        await _saveTokens(
          accessToken: responseData['accessToken'],
          refreshToken: responseData['refreshToken'],
        );

        if (kDebugMode) print("토큰 갱신 성공");
        return;
      }

      // 실패 시 -> 로그 + 예외 처리
      if (kDebugMode) {
        print("Reissue 실패 - 상태코드: ${response.statusCode}, 내용: ${utf8.decode(response.bodyBytes)}");
      }

      if (response.statusCode >= 400 && response.statusCode < 500) {
        throw Exception('Unauthenticated');
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }

    } catch (e) {
      if (kDebugMode) print("Reissue 함수 내부 에러: $e");

      if (e is Exception) rethrow;
      throw Exception('Network Error');
    }
  }

  Future<void> logout(String accessToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auth.logout}');

    try {
      await http.delete( // post -> delete
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

  //accessToken, refreshToken 저장 로직
  Future<void> _saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }
}