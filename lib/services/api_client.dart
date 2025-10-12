// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import '../globals.dart';
import '../screens/login_screen.dart';

const String baseUrl = 'http://localhost:8000/api';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final _storage = const FlutterSecureStorage();
  
  factory ApiClient() {
    return _instance;
  }
  
  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    // 요청 인터셉터: 모든 요청에 토큰 자동 추가
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 401 에러 (세션 만료) 처리
        if (error.response?.statusCode == 401) {
          await _handleSessionExpired();
        }
        return handler.next(error);
      },
    ));
  }
  
  Future<void> _handleSessionExpired() async {
    // 토큰 삭제
    await _storage.delete(key: 'jwt');
    
    // 전역 네비게이터를 사용하여 로그인 화면으로 이동
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      // 모든 화면을 제거하고 로그인 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
      
      // 사용자에게 세션 만료 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }
  
  Future<void> setToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
  }
  
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt');
  }
}

