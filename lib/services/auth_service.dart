// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timemarket_frontend/models/user_model.dart';
import 'package:timemarket_frontend/services/user_service.dart';

// ✅ Dio를 사용하므로 baseUrl과 Dio 인스턴스를 클래스 외부에서 관리합니다.
const String baseUrl = 'http://localhost:8000/api';

class AuthService {
  // ✅ Dio 인스턴스를 생성하여 API 통신에 사용합니다.
  final Dio dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String username, String email, String password) async {
    try {
      final response = await dio.post(
        '$baseUrl/auth/login/',
        data: {'nickname': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['access'];
        await _storage.write(key: 'jwt', value: token);
        return true;
      }
    } catch (e) {
      print('로그인 실패: $e');
    }
    return false;
  }

  Future<bool> signup(
    String username,
    String email,
    String password,
    File? profileImage,
  ) async {
    var uri = Uri.parse('$baseUrl/auth/signup/');
    var formData = FormData.fromMap({
      'nickname': username,
      'email': email,
      'password': password,
    });

    if (profileImage != null) {
      formData.files.add(
        MapEntry(
          'profile_image',
          await MultipartFile.fromFile(profileImage.path),
        ),
      );
    }

    try {
      final response = await dio.postUri(uri, data: formData);
      return response.statusCode == 201;
    } catch (e) {
      print('회원가입 실패: $e');
    }
    return false;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt');
  }

  // ✅ 1. getUser() 함수를 새로 추가합니다.
  // 이 함수는 UserService를 사용하여 현재 로그인된 사용자의 상세 정보를 가져옵니다.
  // ChatListScreen에서 이 함수를 호출하여 _currentUser를 설정합니다.
  Future<User?> getUser() async {
    // UserService의 getMyInfo 함수는 이미 토큰을 포함하여 요청을 보냅니다.
    return await UserService().getMyInfo();
  }
}
