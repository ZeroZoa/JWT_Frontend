import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'AuthInterceptor.dart';

class DioClient{
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;

  factory DioClient() => _instance;

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    // 인터셉터 장착
    _dio.interceptors.add(AuthInterceptor(_dio));
  }
}
