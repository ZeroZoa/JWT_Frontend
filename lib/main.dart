import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jwt_frontend/screens/reset_password_screen.dart';
import 'package:provider/provider.dart';

// ✅ 실제 파일 경로에 맞게 import 해주세요
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. MultiProvider: 앱 전체에서 AuthProvider를 쓸 수 있게 감싸줍니다.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      // 2. MaterialApp.router: GoRouter를 사용하기 위해 .router 생성자를 씁니다.
      child: MaterialApp.router(
        title: 'JWT Project',
        debugShowCheckedModeBanner: false,

        // 3. 라우터 설정 연결
        routerConfig: _router,

        // 4. 테마 설정 (SignupScreen의 빨간색 브랜드 컬러와 통일)
        theme: ThemeData(
          // 브랜드 컬러: 0xFFFF002B (빨강)
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF002B),
            primary: const Color(0xFFFF002B),
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFAFAFA), // 웹용 연한 회색 배경

          // 앱바 스타일 통일
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: Colors.black87),
            titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600
            ),
          ),

          // 버튼 스타일 기본값 설정 (선택사항)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF002B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}


final GoRouter _router = GoRouter(
  initialLocation: '/login', // 앱 실행 시 첫 화면 (로그인)
  routes: [
    // 로그인 화면
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // 회원가입 화면
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    // 홈 화면 (로그인 성공 후 이동)
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text("홈 화면 (로그인 성공)")),
      ),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) => const ResetPasswordScreen(),
    ),
  ],
);