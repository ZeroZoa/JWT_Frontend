class Validators {
  // 인스턴스화 방지 (실무에서 유틸 클래스는 이렇게 막아둡니다)
  Validators._();

  // 정규식 캐싱 (성능 최적화)
  static final _emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static final _nicknameRegex = RegExp(r'^[가-힣a-zA-Z0-9]+$');

  static bool isValidEmailFormat(String email) => _emailRegex.hasMatch(email);

  // 이메일 검증
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!_emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  // 비밀번호 검증
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return null;
  }

  // 비밀번호 확인 검증 (비교 대상이 필요하므로 매개변수 추가)
  static String? validatePasswordConfirm(String? value, String passwordToMatch) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 다시 입력해주세요.';
    }
    if (value != passwordToMatch) {
      return '비밀번호가 일치하지 않습니다.';
    }
    return null;
  }

  // 닉네임 검증
  static String? validateNickname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (value.length < 2 || value.length > 10) {
      return '2~10자 이내로 입력해주세요.';
    }
    if (!_nicknameRegex.hasMatch(value)) {
      return '한글, 영문, 숫자만 가능합니다. (공백 불가)';
    }
    return null;
  }

  // 인증코드 검증
  static String? validateCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '인증 코드를 입력해주세요.';
    }
    if (value.trim().length != 6) {
      return '인증 코드는 6자리입니다.';
    }
    return null;
  }
}