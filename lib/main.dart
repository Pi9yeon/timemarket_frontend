// lib/main.dart
import 'package:flutter/material.dart';
import 'package:timemarket_frontend/screens/time_post_map_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'screens/main_screen.dart'; // ✅ 새로 추가된 MainScreen 임포트

void main() {
  // ✅ 앱의 시작점인 main 함수가 반드시 있어야 합니다.
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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: FutureBuilder<String?>(
        future: _authService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen(); // 로그인 성공 시, MainScreen으로 이동
          } else {
            return const LoginScreen(); // 로그인 실패 또는 토큰 없을 시, LoginScreen으로 이동
          }
        },
      ),
    );
  }
}
