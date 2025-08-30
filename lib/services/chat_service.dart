// lib/services/chat_service.dart

import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart'; // getToken() 함수를 사용하기 위해 import는 유지합니다.

// ✅ 1. ChatService에서 사용할 baseUrl을 직접 정의합니다.
// 안드로이드 에뮬레이터에서 PC의 백엔드 서버에 접속하기 위한 주소입니다.
const String _baseUrl = 'http://localhost:8000/api';

class ChatService {
  // ✅ 2. Dio 인스턴스를 ChatService 내에서 직접 생성합니다.
  final Dio _dio = Dio();

  // ✅ 3. 웹소켓 URL은 _baseUrl을 기반으로 생성합니다.
  // 백엔드 웹소켓 주소는 '/api' 경로가 없으므로 제거해줍니다.
  final String _wsBaseUrl = _baseUrl
      .replaceFirst('http', 'ws')
      .replaceFirst('/api', '');

  // ChatService가 생성될 때 Dio에 기본 설정을 추가합니다.
  ChatService() {
    // Dio Interceptor: 모든 API 요청이 보내지기 전에 먼저 실행되는 중간 처리기입니다.
    // 여기서는 모든 요청 헤더에 인증 토큰(JWT)을 자동으로 추가하는 역할을 합니다.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // AuthService에 있는 getToken() 함수를 사용해 저장된 토큰을 불러옵니다.
          final token = await AuthService().getToken();
          if (token != null) {
            // 토큰이 있으면 Authorization 헤더에 추가합니다.
            options.headers['Authorization'] = 'Bearer $token';
          }
          // 설정이 완료된 요청을 다음 단계로 보냅니다.
          return handler.next(options);
        },
      ),
    );
  }

  // 채팅방 생성/조회 기능은 기존 REST API를 그대로 사용합니다.
  // ✅ receiverId를 매개변수로 추가합니다.
  Future<Map<String, dynamic>?> createOrGetChatRoom(
    int postId,
    int receiverId,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/match/request/',
        // ✅ data에 receiver_id를 추가하여 백엔드로 전송합니다.
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

  // 웹소켓 서버에 연결하는 함수
  Future<WebSocketChannel?> connect(int roomId) async {
    final token = await AuthService().getToken();
    if (token == null) {
      print('인증 토큰이 없어 채팅 서버에 연결할 수 없습니다.');
      return null;
    }

    // 백엔드에서 알려준 URL 형식에 맞게 주소를 만듭니다.
    // ws://10.0.2.2:8000/ws/chat/채팅방번호/?token=JWT토큰
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
