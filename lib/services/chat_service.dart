// lib/services/chat_service.dart

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';

const String _baseUrl = 'http://localhost:8000/api';

class ChatService {
  final Dio _dio = Dio();
  final String _wsBaseUrl = _baseUrl
      .replaceFirst('http', 'ws')
      .replaceFirst('/api', '');

  ChatService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService().getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> createOrGetChatRoom(
    int postId,
    int receiverId,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/match/request/',
        data: {'post_id': postId, 'receiver_id': receiverId},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      print('채팅방 생성/조회 실패: ${e.response?.data}');
    }
    return null;
  }

  Future<List<dynamic>?> getMyChatRooms() async {
    try {
      final response = await _dio.get('$_baseUrl/chat/match/my-chats/');
      return response.data;
    } on DioException catch (e) {
      print('내 채팅방 목록 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // ✅ 1. 채팅방의 이전 대화 내역을 가져오는 함수를 새로 만듭니다.
  //    백엔드의 /api/chat/match/chat/<room_id>/messages/ 엔드포인트를 호출합니다.
  Future<List<dynamic>?> getMessages(int roomId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/chat/match/chat/$roomId/messages/',
      );
      return response.data;
    } on DioException catch (e) {
      print('$roomId번 방 메시지 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  Future<WebSocketChannel?> connect(int roomId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      print('인증 토큰이 없어 채팅 서버에 연결할 수 없습니다.');
      return null;
    }

    final url = '$_wsBaseUrl/ws/chat/$roomId/?token=$token';

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      return channel;
    } catch (e) {
      print('$roomId번 채팅방 연결 실패: $e');
      return null;
    }
  }
}
