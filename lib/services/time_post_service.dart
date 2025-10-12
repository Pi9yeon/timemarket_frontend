// lib/services/time_post_service.dart

import 'package:dio/dio.dart';
import 'package:timemarket_frontend/services/api_client.dart';

class TimePostService {
  final ApiClient _apiClient = ApiClient();
  
  Dio get _dio => _apiClient.dio;

  // ✅ 1. 'type' 매개변수를 선택사항(nullable, String?)으로 변경
  Future<List<dynamic>?> fetchNearbyPosts({
    required double lat,
    required double lng,
    String? type, // 'sale', 'request', 또는 null (전체)
  }) async {
    try {
      // ✅ 2. type 유무에 따라 동적으로 쿼리 파라미터를 생성
      final queryParameters = {'lat': lat.toString(), 'lng': lng.toString()};
      // type이 null이 아니고 비어있지 않을 때만 파라미터에 추가
      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type;
      }

      final response = await _dio.get(
        '/time-posts/',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        print('Failed to load posts, status code: ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      print('Error fetching nearby posts: ${e.response?.data}');
      return null;
    }
  }

  Future<bool> createPost(Map<String, dynamic> postData) async {
    try {
      final response = await _dio.post(
        '/time-posts/create/',
        data: postData,
      );

      return response.statusCode == 201;
    } on DioException catch (e) {
      print('게시글 생성 실패: ${e.response?.data}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPostDetail(int postId) async {
    try {
      final response = await _dio.get('/time-posts/$postId/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      print('게시글 상세 조회 실패: ${e.response?.data}');
    }
    return null;
  }

  Future<bool> updatePost(int postId, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.patch(
        '/time-posts/$postId/',
        data: updateData,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      print('게시글 수정 실패: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      final response = await _dio.delete('/time-posts/$postId/');

      return response.statusCode == 204;
    } on DioException catch (e) {
      print('게시글 삭제 실패: ${e.response?.data}');
      return false;
    }
  }

  Future<List<dynamic>?> fetchBoardPosts() async {
    try {
      final response = await _dio.get('/time-posts/board/');

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
    } on DioException catch (e) {
      print('게시판 조회 실패: ${e.response?.data}');
    }
    return null;
  }
}
