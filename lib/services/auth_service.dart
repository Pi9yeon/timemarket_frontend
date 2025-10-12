// lib/services/auth_service.dart

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timemarket_frontend/models/user_model.dart';
import 'package:timemarket_frontend/services/user_service.dart';
import 'package:timemarket_frontend/services/api_client.dart';

class AuthService {
  // ApiClient 싱글톤 인스턴스 사용
  final ApiClient _apiClient = ApiClient();
  
  Dio get dio => _apiClient.dio;

  Future<bool> login(String username, String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login/',
        data: {'nickname': username, 'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final token = response.data['access'];
        await _apiClient.setToken(token);
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
    XFile? profileImage,
  ) async {
    try {
      print('📝 회원가입 API 호출 시작');
      print('   - 사용자명: $username');
      print('   - 이메일: $email');
      print('   - 프로필 이미지: ${profileImage?.name ?? "없음"}');
      
      var formData = FormData.fromMap({
        'nickname': username,
        'email': email,
        'password': password,
      });

      if (profileImage != null) {
        print('📤 프로필 이미지 추가 중...');
        final bytes = await profileImage.readAsBytes();
        print('✅ 이미지 바이트 읽기 완료: ${bytes.length} bytes');
        
        formData.files.add(
          MapEntry(
            'profile_image',
            MultipartFile.fromBytes(
              bytes,
              filename: profileImage.name,
            ),
          ),
        );
      }

      print('📤 POST /auth/signup/ 요청 전송 중...');
      final response = await dio.post('/auth/signup/', data: formData);
      
      print('✅ 회원가입 응답: ${response.statusCode}');
      print('✅ 응답 데이터: ${response.data}');
      return response.statusCode == 201;
    } on DioException catch (e) {
      print('❌ 회원가입 API 호출 실패');
      print('❌ 상태 코드: ${e.response?.statusCode}');
      print('❌ 에러 메시지: ${e.message}');
      print('❌ 응답 데이터: ${e.response?.data}');
      return false;
    } catch (e, stackTrace) {
      print('❌ 예상치 못한 회원가입 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      return false;
    }
  }

  Future<void> logout() async {
    await _apiClient.deleteToken();
  }

  Future<String?> getToken() async {
    return await _apiClient.getToken();
  }

  // ✅ 1. getUser() 함수를 새로 추가합니다.
  // 이 함수는 UserService를 사용하여 현재 로그인된 사용자의 상세 정보를 가져옵니다.
  // ChatListScreen에서 이 함수를 호출하여 _currentUser를 설정합니다.
  Future<User?> getUser() async {
    // UserService의 getMyInfo 함수는 이미 토큰을 포함하여 요청을 보냅니다.
    return await UserService().getMyInfo();
  }
}
