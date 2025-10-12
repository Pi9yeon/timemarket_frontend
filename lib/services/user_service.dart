// lib/services/user_service.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:timemarket_frontend/models/user_model.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();
  
  Dio get _dio => _apiClient.dio;

  Future<User?> getMyInfo() async {
    try {
      final response = await _dio.get('/users/me/');
      
      if (response.statusCode == 200) {
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      print('사용자 정보 조회 실패: ${e.response?.data}');
    }
    return null;
  }

  // ✅ 프로필 이미지 업데이트 API 메서드
  Future<bool> updateProfileImage(File imageFile) async {
    try {
      var formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _dio.patch('/users/me/', data: formData);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('프로필 이미지 업데이트 API 호출 실패: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> updateMyInfo(String username, String email) async {
    try {
      final response = await _dio.patch(
        '/users/me/',
        data: {'username': username, 'email': email},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('사용자 정보 업데이트 실패: ${e.response?.data}');
      return false;
    }
  }

  // ✅ 새로운 비밀번호 변경 API 메서드
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await _dio.post(
        '/users/change-password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      print('비밀번호 변경 API 호출 실패: ${e.response?.data}');
      return false;
    }
  }
}
