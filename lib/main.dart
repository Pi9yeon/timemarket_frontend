// lib/main.dart

import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/login_screen.dart';
import 'package:timemarket_frontend/services/auth_service.dart';
import 'screens/time_post_map_screen.dart'; // ✅ 지도 화면을 기본 홈으로 설정

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Market',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // ✅ 앱 전체에 일관된 앱 바 디자인을 적용합니다.
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: FutureBuilder<String?>(
        // 앱 시작 시 저장된 토큰이 있는지 확인합니다.
        future: _authService.getToken(),
        builder: (context, snapshot) {
          // 로딩 중일 때 로딩 스피너를 보여줍니다.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 토큰이 존재하면(로그인 상태) 지도 화면으로 바로 이동합니다.
          if (snapshot.hasData && snapshot.data != null) {
            return const TimePostMapScreen();
          } else {
            // 토큰이 없으면 로그인 화면을 보여줍니다.
            return LoginScreen();
          }
        },
      ),
    );
  }
}
