// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/profile_screen.dart';
import 'package:timemarket_frontend/screens/time_post_list_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'time_post_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();

  // 현재는 지도 화면만 보여주지만, 추후 다른 화면을 추가할 수 있습니다.
  final Widget _currentScreen = const TimePostMapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 모든 화면에 공통으로 보일 상단 바
      appBar: AppBar(
        title: const Text(
          'TimeMarket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 자동 생성 방지
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
            tooltip: '게시글 목록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimePostListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: '마이 페이지',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: '로그아웃',
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              // 모든 이전 화면을 제거하고 로그인 화면으로 이동
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      // ✅ 상단 바 아래에 보여줄 내용물 (지도 화면)
      body: _currentScreen,
    );
  }
}
