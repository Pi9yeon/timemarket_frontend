import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 1. const String baseUrl = 'http://localhost:8000/api';
const String baseUrl = 'http://10.0.2.2:8000/api';
// 3. const String baseUrl = 'http://172.30.1.50:8000/api';

class AuthService {
  Future<bool> login(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nickname': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['access'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return true;
    }
    return false;
  }

  /// 프로필 이미지 포함 회원가입 (profileImage는 null 가능)
  Future<bool> signup(
    String username,
    String email,
    String password,
    File? profileImage,
  ) async {
    var uri = Uri.parse('$baseUrl/auth/signup/');
    var request = http.MultipartRequest('POST', uri);

    request.fields['nickname'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;

    if (profileImage != null) {
      var stream = http.ByteStream(profileImage.openRead());
      var length = await profileImage.length();

      var multipartFile = http.MultipartFile(
        'profile_image', // Django에서 받는 필드명과 일치해야 함
        stream,
        length,
        filename: profileImage.path.split('/').last,
      );
      request.files.add(multipartFile);
    }

    try {
      var response = await request.send();

      if (response.statusCode == 201) {
        print('회원가입 성공!');
        return true;
      } else {
        // 📌 백엔드에서 보낸 상세 에러 메시지를 읽어서 출력
        var responseBody = await response.stream.bytesToString();
        print('회원가입 실패 (상태 코드: ${response.statusCode}):');
        print('에러 내용: $responseBody');
        return false;
      }
    } catch (e) {
      // 📌 네트워크 연결 실패 등의 예외 처리
      print('회원가입 중 네트워크 오류 발생: $e');
      return false;
    }

    // var response = await request.send();

    // return response.statusCode == 201;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}
