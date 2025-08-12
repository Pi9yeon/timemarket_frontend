import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/profile_screen.dart';
import 'time_post_map_screen.dart';
import 'time_post_list_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0; // 현재 선택된 화면 인덱스 (0: 지도, 1: 목록)

  // 각 내비게이션 탭에 해당하는 화면 목록
  final List<Widget> _widgetOptions = <Widget>[
    const TimePostMapScreen(),
    const TimePostListScreen(),
    ProfileScreen(), // 마이페이지 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeMarket'),
        actions: [
          // 공통적으로 사용될 상단 버튼들
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '게시글 목록',
            onPressed: () => _onItemTapped(1), // 목록 화면으로 이동
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '마이 페이지',
            onPressed: () => _onItemTapped(2), // 마이 페이지로 이동
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // 하단 내비게이션 바는 추후 필요 시 추가 가능
    );
  }
}
