// lib/services/user_service.dart

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timemarket_frontend/models/user_model.dart';
import 'package:timemarket_frontend/services/api_client.dart';

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

  // ✅ 프로필 이미지 업데이트 API 메서드 (웹 환경 지원)
  Future<bool> updateProfileImage(XFile imageFile) async {
    try {
      print('📤 프로필 이미지 업로드 시작: ${imageFile.name}');
      print('📤 파일 경로: ${imageFile.path}');
      
      // XFile에서 바이트 데이터 읽기 (웹/모바일 모두 지원)
      final bytes = await imageFile.readAsBytes();
      print('✅ 이미지 바이트 읽기 완료: ${bytes.length} bytes');
      
      // MIME 타입 추론
      String? mimeType;
      final fileName = imageFile.name.toLowerCase();
      if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (fileName.endsWith('.webp')) {
        mimeType = 'image/webp';
      }
      
      print('📤 MIME 타입: $mimeType');
      
      var formData = FormData.fromMap({
        'profile_image': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      });

      print('📤 PATCH /users/me/ 요청 전송 중...');
      print('📤 FormData 필드: ${formData.fields.map((e) => e.key).toList()}');
      print('📤 FormData 파일: ${formData.files.map((e) => '${e.key}: ${e.value.filename} (${e.value.length} bytes)').toList()}');
      
      final response = await _dio.patch(
        '/users/me/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      print('✅ 프로필 이미지 업데이트 성공: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');
      print('✅ 응답 헤더: ${response.headers}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('❌ 프로필 이미지 업데이트 API 호출 실패');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      print('❌ 에러 메시지: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      print('❌ 요청 헤더: ${e.requestOptions.headers}');
      return false;
    } catch (e, stackTrace) {
      print('❌ 예상치 못한 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
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
