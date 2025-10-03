// lib/services/time_post_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

const String baseUrl = 'http://localhost:8000/api';

class TimePostService {
  final AuthService _authService = AuthService();

  // ✅ 1. 'type' 매개변수를 선택사항(nullable, String?)으로 변경
  Future<List<dynamic>?> fetchNearbyPosts({
    required double lat,
    required double lng,
    String? type, // 'sale', 'request', 또는 null (전체)
  }) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    // ✅ 2. type 유무에 따라 동적으로 쿼리 파라미터를 생성
    final queryParameters = {'lat': lat.toString(), 'lng': lng.toString()};
    // type이 null이 아니고 비어있지 않을 때만 파라미터에 추가
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }

    final uri = Uri.parse(
      '$baseUrl/time-posts/',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return jsonDecode(decodedBody) as List<dynamic>;
      } else {
        print('Failed to load posts, status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching nearby posts: $e');
      return null;
    }
  }

  // (이하 다른 함수들은 기존과 동일)

  Future<bool> createPost(Map<String, dynamic> postData) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final utf8Body = utf8.encode(jsonEncode(postData));

    final response = await http.post(
      Uri.parse('$baseUrl/time-posts/create/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: utf8Body,
    );

    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> getPostDetail(int postId) async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> updatePost(int postId, Map<String, dynamic> updateData) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.patch(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    return response.statusCode == 200;
  }

  Future<bool> deletePost(int postId) async {
    final token = await _authService.getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/time-posts/$postId/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 204;
  }

  Future<List<dynamic>?> fetchBoardPosts() async {
    final token = await _authService.getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/time-posts/board/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    return null;
  }
}
