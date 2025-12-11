import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_frontend/config/api_config.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _storage = const FlutterSecureStorage();

  late Future<Map<String, dynamic>> _myInfoFuture;

  @override
  void initState() {
    super.initState();
    // 앱이 켜질 때 데이터 요청 시작
    _myInfoFuture = fetchMyInfo();
  }

  // --- [공통] 로그아웃 및 세션 만료 처리 ---
  Future<void> _handleUnauthorized() async {
    // 1. 저장된 토큰 삭제 (모두 삭제)
    await _storage.deleteAll();

    if (!mounted) return;

    // 2. 로그인 화면으로 이동 (뒤로가기 방지)
    // '/login' 부분은 실제 라우트 이름에 맞게 수정하세요.
    context.go('/login');
    //Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // --- [기능 1] 내 정보 조회 (수정됨) ---
  Future<Map<String, dynamic>> fetchMyInfo() async {
    // 1. 저장된 토큰 꺼내기
    String? token = await _storage.read(key: 'accessToken');

    if (token == null) {
      // 토큰이 없으면 로그인 페이지로 이동
      await _handleUnauthorized();
      throw Exception("로그인 토큰이 없습니다.");
    }

    // 2. HTTP GET 요청
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.myinfo}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 3. 응답 처리
    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return jsonDecode(responseBody) as Map<String, dynamic>;
    }
    // [추가] 401 Unauthorized 처리 (토큰 만료 등)
    else if (response.statusCode == 401 || response.statusCode == 403) {
      await _handleUnauthorized();
      throw Exception("인증이 만료되었습니다.");
    }
    else {
      throw Exception("데이터 로드 실패: ${response.statusCode}");
    }
  }

  // --- [기능 2] 로그아웃 로직 (추가됨) ---
  Future<void> _logout() async {
    // 사용자 확인 (선택 사항)
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("로그아웃"),
        content: const Text("정말 로그아웃 하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("확인")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      String? token = await _storage.read(key: 'accessToken');

      // 백엔드에 로그아웃 요청 (Redis 삭제용) - 실패해도 프론트에서는 지워야 함
      if (token != null) {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auth.logout}'), // API 경로 확인 필요
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print("로그아웃 요청 중 에러 발생 (무시): $e");
    } finally {
      // 성공하든 실패하든 프론트엔드 데이터는 삭제하고 이동
      await _handleUnauthorized();
    }
  }

  void _onRefresh() {
    setState(() {
      _myInfoFuture = fetchMyInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 정보"),
        centerTitle: true,
        actions: [
          // 1. 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: "새로고침",
          ),
          // 2. [추가] 로그아웃 버튼
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: "로그아웃",
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _myInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError) {
            // 401 에러 등으로 인해 이동 중일 때는 에러 메시지 대신 로딩을 보여주는 게 깔끔함
            if (snapshot.error.toString().contains("인증이 만료")) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text("에러 발생: ${snapshot.error}"));
          }
          else if (snapshot.hasData) {
            final data = snapshot.data!;
            return _buildInfoBody(data);
          }
          else {
            return const Center(child: Text("정보가 없습니다."));
          }
        },
      ),
    );
  }

  Widget _buildInfoBody(Map<String, dynamic> data) {
    String nickname = data['nickname'] ?? '알 수 없음';
    String email = data['email'] ?? '-';
    String role = data['role'] ?? 'USER';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.person_pin, size: 60, color: Colors.blue),
                const SizedBox(height: 10),
                Text(
                  nickname,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: role == 'ADMIN' ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Role: $role",
                    style: TextStyle(
                      color: role == 'ADMIN' ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// import 'dart:convert';
//
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:jwt_frontend/config/api_config.dart';
//
// class MainScreen extends StatefulWidget{
//   const MainScreen({super.key});
//
//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   final _storage = const FlutterSecureStorage();
//
//   late Future<Map<String, dynamic>> _myInfoFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // 앱이 켜질 때 데이터 요청 시작
//     _myInfoFuture = fetchMyInfo();
//   }
//
//   Future<Map<String, dynamic>> fetchMyInfo() async {
//     // 1. 저장된 토큰 꺼내기
//     String? token = await _storage.read(key: 'accessToken');
//
//     if (token == null) {
//       throw Exception("로그인 토큰이 없습니다.");
//     }
//
//     // 2. HTTP GET 요청 (헤더에 토큰 포함)
//     final response = await http.get(
//       Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.myinfo}'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//       },
//     );
//
//     // 3. 응답 처리
//     if (response.statusCode == 200) {
//       // 한글 깨짐 방지 디코딩
//       String responseBody = utf8.decode(response.bodyBytes);
//       // JSON을 Map으로 변환해서 반환
//       return jsonDecode(responseBody) as Map<String, dynamic>;
//     } else {
//       throw Exception("데이터 로드 실패: ${response.statusCode}");
//     }
//   }
//
//   // --- [이벤트] 새로고침 버튼 클릭 시 실행 ---
//   void _onRefresh() {
//     setState(() {
//       // Future를 재할당하면 FutureBuilder가 다시 실행됨
//       _myInfoFuture = fetchMyInfo();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("내 정보"),
//         centerTitle: true,
//         actions: [
//           // 1. 새로고침 버튼
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _onRefresh,
//           ),
//         ],
//       ),
//       // 2. 비동기 데이터 빌더
//       body: FutureBuilder<Map<String, dynamic>>(
//         future: _myInfoFuture,
//         builder: (context, snapshot) {
//           // 로딩 중
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           // 에러 발생
//           else if (snapshot.hasError) {
//             return Center(child: Text("에러 발생: ${snapshot.error}"));
//           }
//           // 데이터 도착
//           else if (snapshot.hasData) {
//             final data = snapshot.data!;
//             return _buildInfoBody(data);
//           }
//           // 그 외
//           else {
//             return const Center(child: Text("정보가 없습니다."));
//           }
//         },
//       ),
//     );
//   }
//   Widget _buildInfoBody(Map<String, dynamic> data) {
//     // 백엔드 JSON 키 값: id, email, nickname, role
//     String nickname = data['nickname'] ?? '알 수 없음';
//     String email = data['email'] ?? '-';
//     String role = data['role'] ?? 'USER';
//
//     return Padding(
//       padding: const EdgeInsets.all(24.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Welcome!",
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 30),
//
//           // 프로필 카드
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.2),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 )
//               ],
//             ),
//             child: Column(
//               children: [
//                 const Icon(Icons.person_pin, size: 60, color: Colors.blue),
//                 const SizedBox(height: 10),
//                 Text(
//                   nickname,
//                   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   email,
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//                 const SizedBox(height: 20),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: role == 'ADMIN' ? Colors.red[50] : Colors.green[50],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "Role: $role",
//                     style: TextStyle(
//                       color: role == 'ADMIN' ? Colors.red : Colors.green,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
