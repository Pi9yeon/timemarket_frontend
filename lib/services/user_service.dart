// lib/services/user_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // multipart/form-data 사용을 위해 필요
import 'package:mime/mime.dart'; // multipart/form-data 사용을 위해 필요
import 'package:timemarket_frontend/models/user_model.dart';
import 'auth_service.dart';

const String baseUrl = 'http://localhost:8000/api';
// 2. const String baseUrl = 'http://10.0.2.2:8000/api';
// 3. const String baseUrl = 'http://172.30.1.50:8000/api';

class UserService {
  final AuthService authService = AuthService();

  Future<User?> getMyInfo() async {
    final token = await authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/users/me/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  // ✅ 프로필 이미지 업데이트 API 메서드
  Future<bool> updateProfileImage(File imageFile) async {
    final token = await authService.getToken();
    if (token == null) return false;

    var uri = Uri.parse('$baseUrl/users/me/');
    var request = http.MultipartRequest('PATCH', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // 이미지 파일을 MultipartFile로 변환하여 요청에 추가
    final mimeTypeData = lookupMimeType(
      imageFile.path,
      headerBytes: [0xFF, 0xD8],
    )?.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'profile_image',
        imageFile.path,
        contentType:
            mimeTypeData != null
                ? MediaType(mimeTypeData[0], mimeTypeData[1])
                : null,
      ),
    );

    try {
      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print('프로필 이미지 업데이트 API 호출 실패: $e');
      return false;
    }
  }

  Future<bool> updateMyInfo(String username, String email) async {
    final token = await authService.getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/users/me/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': username, 'email': email}),
    );
    return response.statusCode == 200;
  }

  // ✅ 새로운 비밀번호 변경 API 메서드
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final token = await authService.getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/change-password/'), // 📌 Django에 구현될 엔드포인트
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('비밀번호 변경 API 호출 실패: $e');
      return false;
    }
  }
}
