import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../config/api_config.dart';
import 'TokenStorage.dart';

class AuthInterceptor extends Interceptor{

  late final Dio _dio;

  AuthInterceptor(this._dio);
  // 요청 전: AccessToken 헤더 주입
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 401 에러(토큰 만료)이고, 재발급 요청 자체가 아니어야 함
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains(ApiConfig.auth.reissue)) {
      debugPrint('[Dio] 401 Error detected. Trying to reissue token...');

      try {
        final refreshToken = await TokenStorage.getRefreshToken();
        final accessToken = await TokenStorage.getAccessToken();

        if (refreshToken == null) {
          // 리프레시 토큰 없으면 로그아웃 처리
          return handler.next(err);
        }

        // 독립된 Dio 생성 (순환 참조 방지)
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

        // 재발급 요청 (백엔드 DTO 규격에 맞춤)
        final response = await refreshDio.post(
          ApiConfig.auth.reissue,
          data: {
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          },
        );

        // 새 토큰 저장
        final newAccessToken = response.data['accessToken'];
        final newRefreshToken = response.data['refreshToken'];
        await TokenStorage.saveTokens(newAccessToken, newRefreshToken);

        debugPrint('[Dio] Token reissued successfully!');

        // 실패했던 원래 요청의 헤더 교체
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

        // 원래 요청 재시도
        final clonedRequest = await _dio.fetch(err.requestOptions);

        // 재시도 성공 결과를 반환
        return handler.resolve(clonedRequest);

      } catch (e) {
        debugPrint('[Dio] Reissue failed: $e');
        // 재발급 실패 -> 강제 로그아웃 (토큰 삭제)
        await TokenStorage.deleteAll();
        // 필요 시 여기서 로그인 화면 이동 로직 추가 가능
        return handler.next(err);
      }
    }
    super.onError(err, handler);
  }
}