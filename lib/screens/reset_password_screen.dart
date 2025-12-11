import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/validators.dart';

class ResetPasswordScreen extends StatefulWidget{
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  final _emailFocus = FocusNode();
  final _verificationCodeFocus = FocusNode();
  final _pwFocus = FocusNode();
  final _pwConfirmFocus = FocusNode();

  bool _isLoading = false;
  bool _isCodeSent = false; //코드 전송 여부
  bool _isVerified = false; //코드 인증 여부
  String? _verifiedToken;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

    _emailFocus.dispose();
    _verificationCodeFocus.dispose();
    _pwFocus.dispose();
    _pwConfirmFocus.dispose();

    super.dispose();
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating, // 웹에서 더 보기 좋음
        width: 400, // 웹에서 너무 넓지 않게
      ),
    );
  }

  void _handleApiError(http.Response response) {
    try {
      final body = json.decode(utf8.decode(response.bodyBytes));
      _showSnackBar(body['message'] ?? '오류가 발생했습니다.', isError: true);
    } catch (_) {
      _showSnackBar('알 수 없는 오류가 발생했습니다.', isError: true);
    }
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    if(email.isEmpty || !Validators.isValidEmailFormat(email)) {
      _showSnackBar('올바른 이메일을 입력해주세요.', isError: true);
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    try{
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.email.sendPasswordResetVerificationCode}');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if(response.statusCode == 200) {
        setState(() => _isCodeSent = true);
        _showSnackBar('인증 코드가 전송되었습니다.');

        Future.delayed(const Duration(milliseconds: 200), () {
          _verificationCodeFocus.requestFocus();
        });
      } else {
        _handleApiError(response);
      }
    }catch (e) {
      _showSnackBar('서버 연결 실패: $e', isError: true);
    }finally{
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkVerificationCode() async {
    final submittedCode = _verificationCodeController.text.trim();

    if(submittedCode.isEmpty){
      _showSnackBar('인증 코드를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try{
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.email.checkVerificationCode}');

      final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email':_emailController.text.trim(),
            'code': submittedCode,
          })
      );

      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isVerified = true;
          _verifiedToken = data['verifiedToken'];
        });

        _showSnackBar('인증되었습니다.');
        _pwFocus.requestFocus();
      } else{
        _handleApiError(response);
      }
    } catch (e) {
      _showSnackBar('인증 확인 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async{
    if(!_formKey.currentState!.validate()) return;

    if(!_isVerified || _verifiedToken == null){
      _showSnackBar('이메일 인증을 완료해주세요.', isError: true);
      _emailFocus.requestFocus();
      return;
    }

    FocusScope.of(context).unfocus();
    setState(()  => _isLoading = true);

    try{
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.resetPassword}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'verifiedToken': _verifiedToken,
          'newPassword1': _passwordController.text,
          'newPassword2': _passwordConfirmController.text,
        }),
      );

      if(response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('비밀번호가 변경되었습니다.다시 로그인해주세요.');

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _handleApiError(response);
      }
    } catch (e) {
      _showSnackBar('서버 연결 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.', isError: true);
      print('Find Password Error: $e');
    } finally{
      if(mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(158, 158, 158, 0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                  'JWT Server 비밀번호 찾기',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _AppTextFormField(
                          label: '이메일',
                          controller: _emailController,
                          focusNode: _emailFocus,
                          hint: 'example@email.com',
                          enabled: !_isCodeSent,
                          validator: Validators.validateEmail, // utils 사용
                          keyboardType: TextInputType.emailAddress,
                          onFieldSubmitted: (_) => _sendVerificationCode(),
                        ),
                      ),

                      const SizedBox(width: 8),

                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: (_isCodeSent || _isLoading) ? null : _sendVerificationCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01AD70),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('인증요청'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isCodeSent) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _AppTextFormField(
                            label: '인증코드',
                            controller: _verificationCodeController,
                            focusNode: _verificationCodeFocus,
                            hint: '6자리 코드',
                            enabled: !_isVerified,
                            validator: Validators.validateCode,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (_) => _checkVerificationCode(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: (_isVerified || _isLoading) ? null : _checkVerificationCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isVerified ? Colors.grey : const Color(0xFF01AD70),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(_isVerified ? '완료' : '확인'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. 비밀번호
                  _AppTextFormField(
                    label: '비밀번호',
                    controller: _passwordController,
                    focusNode: _pwFocus,
                    hint: '8자 이상 입력',
                    obscureText: _obscurePassword,
                    validator: Validators.validatePassword, // utils 사용
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_pwConfirmFocus),
                  ),

                  const SizedBox(height: 16),

                  // 4. 비밀번호 확인
                  _AppTextFormField(
                    label: '비밀번호 확인',
                    controller: _passwordConfirmController,
                    focusNode: _pwConfirmFocus,
                    hint: '비밀번호 재입력',
                    obscureText: _obscurePasswordConfirm,
                    validator: (val) => Validators.validatePasswordConfirm(val, _passwordController.text),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                    ),
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleResetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF01AD70),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('비밀번호 재설정'),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool obscureText;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const _AppTextFormField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction, // 입력 시 즉시 검증
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }
}