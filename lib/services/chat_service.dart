// lib/services/chat_service.dart

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_room_model.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();
  final String _wsBaseUrl = baseUrl
      .replaceFirst('http', 'ws')
      .replaceFirst('/api', '');
      
  Dio get _dio => _apiClient.dio;
      
  // 디버그용 URL 확인 메서드
  String get debugInfo => '''
🔍 ChatService 연결 정보:
- HTTP Base URL: $baseUrl
- WebSocket Base URL: $_wsBaseUrl
- 예상 WebSocket URL 형식: $_wsBaseUrl/ws/chat/[roomId]/?token=[token]
  ''';


  Future<Map<String, dynamic>?> createOrGetChatRoom(
    int postId,
    int receiverId,
  ) async {
    try {
      final response = await _dio.post(
        '/chat/match/request/',
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

  Future<List<ChatRoom>?> getMyChatRooms() async {
    try {
      final response = await _dio.get('/chat/match/my-chats/');
      print('🔍 백엔드 채팅방 응답: ${response.data}'); // 디버그 출력
      
      if (response.data is List) {
        final chatRooms = (response.data as List)
            .where((roomJson) => roomJson != null)
            .map((roomJson) {
              try {
                print('🔍 개별 채팅방 데이터: $roomJson'); // 디버그 출력
                final chatRoom = ChatRoom.fromJson(roomJson);
                print('🔍 파싱된 채팅방 - ID: ${chatRoom.id}, Post: ${chatRoom.post}'); // 디버그 출력
                return chatRoom;
              } catch (e) {
                print('❌ 채팅방 파싱 오류: $e, 데이터: $roomJson');
                return null;
              }
            })
            .where((room) => room != null)
            .cast<ChatRoom>()
            .toList();
        
        print('🔍 최종 채팅방 목록 개수: ${chatRooms.length}'); // 디버그 출력
        return chatRooms;
      }
      return [];
    } on DioException catch (e) {
      print('❌ 내 채팅방 목록 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // ✅ 1. 채팅방의 이전 대화 내역을 가져오는 함수를 새로 만듭니다.
  //    백엔드의 /api/chat/match/chat/<room_id>/messages/ 엔드포인트를 호출합니다.
  Future<List<dynamic>?> getMessages(int roomId) async {
    try {
      final response = await _dio.get(
        '/chat/match/chat/$roomId/messages/',
      );
      return response.data;
    } on DioException catch (e) {
      print('$roomId번 방 메시지 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  Future<WebSocketChannel?> connect(int roomId) async {
    final token = await _apiClient.getToken();
    if (token == null) {
      print('❌ 인증 토큰이 없어 채팅 서버에 연결할 수 없습니다.');
      return null;
    }

    final url = '$_wsBaseUrl/ws/chat/$roomId/?token=$token';
    print('🔗 웹소켓 연결 시도: $url');

    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      
      // 연결 상태 확인을 위한 테스트 메시지 전송
      channel.ready.then((_) {
        print('✅ 웹소켓 연결 성공: Room $roomId');
        // 연결 확인 메시지 전송
        channel.sink.add('{"type": "ping"}');
      }).catchError((error) {
        print('❌ 웹소켓 연결 실패: $error');
      });
      
      return channel;
    } catch (e) {
      print('❌ $roomId번 채팅방 연결 실패: $e');
      return null;
    }
  }
}
