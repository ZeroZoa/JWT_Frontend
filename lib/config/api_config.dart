class ApiConfig{
  ApiConfig._();

  //Base url
  static const String baseUrl = 'http://localhost:8080';
  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return 'http://localhost:8080'; // 웹 브라우저 & iOS 시뮬레이터
  //   } else {
  //     // 안드로이드 에뮬레이터에서는 localhost가 10.0.2.2입니다.
  //     // 실기기 연결 시에는 내 컴퓨터의 내부 IP(예: 192.168.x.x)를 적어야 합니다.
  //     return 'http://10.0.2.2:8080';
  //   }

  //API 모음
  static const _MembersApi members = _MembersApi();
  static const _EmailApi email = _EmailApi();
}

class _MembersApi {
  const _MembersApi();

  static const String _path = '/api/members';

  String get signup => '$_path/signup';
  String get login => '$_path/login';
  String get logout => '$_path/logout';
  String get reissue => '$_path/reissue';
}

class _EmailApi {
  const _EmailApi();

  static const String _path = '/api/email';

  String get sendVerificationCode => '$_path/send-verification-code';
  String get checkVerificationCode => '$_path/check-verification-code';
}