import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_frontend/config/api_config.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

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
    _myInfoFuture = fetchMyInfo();
  }

  Future<void> _handleUnauthorized() async {
    await _storage.deleteAll();
    if (!mounted) return;
    context.go('/login');
  }

  Future<Map<String, dynamic>> fetchMyInfo() async {
    String? token = await _storage.read(key: 'accessToken');

    if (token == null) {
      await _handleUnauthorized();
      throw Exception("로그인 토큰이 없습니다.");
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.members.myinfo}');

    //첫 번째 요청 시도
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    //토큰 만료 (401, 403) -> tryReissue 호출
    else if (response.statusCode == 401 || response.statusCode == 403) {
      return await _tryReissue(url);
    }

    //그 외 에러
    else {
      throw Exception("데이터 로드 실패: ${response.statusCode}");
    }
  }

  Future<void> _logout() async {
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

      if (token != null) {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auth.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      if (kDebugMode) print("로그아웃 요청 중 에러 발생 (무시): $e");
    } finally {
      await _handleUnauthorized();
    }
  }

  Future<Map<String, dynamic>> _tryReissue(Uri url) async {
    if (kDebugMode) print("토큰 만료. 갱신 및 재요청 시도 중");

    final authProvider = context.read<AuthProvider>();
    final bool isRefreshed = await authProvider.reissueToken();

    if (isRefreshed) {
      // 새 토큰 읽기
      final newToken = await _storage.read(key: 'accessToken');

      // 재요청
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        },
      );

      // 재요청 성공 시 데이터 반환
      if (response.statusCode == 200) {
        if (kDebugMode) print("재발급 후 요청 성공");
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    }

    if (kDebugMode) print("토큰 재발급 실패. 로그아웃 진행.");
    await _handleUnauthorized(); // 로그아웃 및 로그인 화면 이동
    throw Exception("세션이 만료되었습니다. 다시 로그인해주세요.");
  }

  //내 정보 새로고침
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