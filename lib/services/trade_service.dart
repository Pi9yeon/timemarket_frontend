// lib/services/trade_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/trade_model.dart';
import 'auth_service.dart';

const String _baseUrl = 'http://localhost:8000/api';

class TradeService {
  final Dio _dio = Dio();

  TradeService() {
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

  // 거래 요청 목록 조회 (특정 채팅방)
  Future<List<TradeRequest>?> getTradeRequests(int roomId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/chat/match/chat/$roomId/trades/',
      );
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TradeRequest.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print('거래 요청 목록 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // 사용자의 모든 거래내역 조회
  Future<List<TradeRequest>?> getUserTradeHistory() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/trades/history/',
      );
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TradeRequest.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print('거래내역 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // 거래내역 필터링 조회 (상태별)
  Future<List<TradeRequest>?> getUserTradeHistoryByStatus(String status) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/trades/history/',
        queryParameters: {'status': status},
      );
      
      if (response.data is List) {
        return (response.data as List)
            .map((json) => TradeRequest.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      print('거래내역 필터링 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // 거래 요청 생성 (REST API)
  Future<TradeRequest?> createTradeRequest(
    int roomId,
    CreateTradeRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/chat/match/chat/$roomId/trades/create/',
        data: {
          'proposed_price': request.proposedPrice,
          'proposed_hours': request.proposedHours,
          'message': request.message,
        },
      );
      
      if (response.statusCode == 201) {
        return TradeRequest.fromJson(response.data);
      }
    } on DioException catch (e) {
      print('거래 요청 생성 실패: ${e.response?.data}');
    }
    return null;
  }

  // 거래 요청 상세 조회
  Future<TradeRequest?> getTradeRequest(int tradeId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/chat/match/trades/$tradeId/',
      );
      
      return TradeRequest.fromJson(response.data);
    } on DioException catch (e) {
      print('거래 요청 상세 조회 실패: ${e.response?.data}');
      return null;
    }
  }

  // 거래 요청 응답 (REST API)
  Future<TradeRequest?> respondToTradeRequest(
    int tradeId,
    bool accept,
    {String? message}
  ) async {
    try {
      final response = await _dio.patch(
        '$_baseUrl/chat/match/trades/$tradeId/',
        data: accept 
          ? {'requester_accepted': true}
          : {'receiver_accepted': false},
      );
      
      return TradeRequest.fromJson(response.data);
    } on DioException catch (e) {
      print('거래 요청 응답 실패: ${e.response?.data}');
      return null;
    }
  }
}

// WebSocket을 통한 실시간 거래 관리 클래스
class TradeWebSocketManager {
  WebSocketChannel? _channel;
  final List<Function(TradeMessage)> _messageHandlers = [];
  final List<Function(TradeRequest)> _tradeRequestHandlers = [];
  final List<Function(TradeRequest)> _tradeUpdateHandlers = [];
  final List<Function(String)> _errorHandlers = [];

  // WebSocket 채널 설정
  void setChannel(WebSocketChannel? channel) {
    _channel = channel;
  }

  // 메시지 핸들러 등록
  void addMessageHandler(Function(TradeMessage) handler) {
    _messageHandlers.add(handler);
  }

  void addTradeRequestHandler(Function(TradeRequest) handler) {
    _tradeRequestHandlers.add(handler);
  }

  void addTradeUpdateHandler(Function(TradeRequest) handler) {
    _tradeUpdateHandlers.add(handler);
  }

  void addErrorHandler(Function(String) handler) {
    _errorHandlers.add(handler);
  }

  // 핸들러 제거
  void removeMessageHandler(Function(TradeMessage) handler) {
    _messageHandlers.remove(handler);
  }

  void removeTradeRequestHandler(Function(TradeRequest) handler) {
    _tradeRequestHandlers.remove(handler);
  }

  void removeTradeUpdateHandler(Function(TradeRequest) handler) {
    _tradeUpdateHandlers.remove(handler);
  }

  void removeErrorHandler(Function(String) handler) {
    _errorHandlers.remove(handler);
  }

  // WebSocket 메시지 처리
  void handleMessage(String message) {
    try {
      final data = jsonDecode(message);
      final tradeMessage = TradeMessage.fromJson(data);

      // 모든 메시지 핸들러에 전달
      for (final handler in _messageHandlers) {
        handler(tradeMessage);
      }

      // 메시지 타입별 처리
      switch (tradeMessage.type) {
        case 'trade_request':
          if (tradeMessage.data != null) {
            final tradeRequest = TradeRequest.fromJson(tradeMessage.data!);
            for (final handler in _tradeRequestHandlers) {
              handler(tradeRequest);
            }
          }
          break;

        case 'trade_status_update':
          if (tradeMessage.data != null) {
            final tradeRequest = TradeRequest.fromJson(tradeMessage.data!);
            for (final handler in _tradeUpdateHandlers) {
              handler(tradeRequest);
            }
          }
          break;

        case 'error':
          final errorMessage = tradeMessage.message ?? '알 수 없는 오류가 발생했습니다';
          for (final handler in _errorHandlers) {
            handler(errorMessage);
          }
          break;
      }
    } catch (e) {
      print('거래 메시지 처리 오류: $e');
      for (final handler in _errorHandlers) {
        handler('메시지 처리 중 오류가 발생했습니다');
      }
    }
  }

  // 거래 요청 전송
  void sendTradeRequest(CreateTradeRequest request) {
    if (_channel == null) {
      print('WebSocket 연결이 없습니다');
      return;
    }

    try {
      final message = jsonEncode(request.toJson());
      _channel!.sink.add(message);
    } catch (e) {
      print('거래 요청 전송 실패: $e');
    }
  }

  // 거래 응답 전송
  void sendTradeResponse(TradeResponse response) {
    if (_channel == null) {
      print('WebSocket 연결이 없습니다');
      return;
    }

    try {
      final message = jsonEncode(response.toJson());
      _channel!.sink.add(message);
    } catch (e) {
      print('거래 응답 전송 실패: $e');
    }
  }

  // 거래 수락
  void acceptTrade(int tradeRequestId, {String? message}) {
    final response = TradeResponse.accept(tradeRequestId, message: message);
    sendTradeResponse(response);
  }

  // 거래 거절
  void rejectTrade(int tradeRequestId, {String? message}) {
    final response = TradeResponse.reject(tradeRequestId, message: message);
    sendTradeResponse(response);
  }

  // 정리
  void dispose() {
    _messageHandlers.clear();
    _tradeRequestHandlers.clear();
    _tradeUpdateHandlers.clear();
    _errorHandlers.clear();
  }
}

// 통합 거래 관리자 클래스
class TradeManager {
  final TradeService _tradeService = TradeService();
  final TradeWebSocketManager _wsManager = TradeWebSocketManager();
  
  // 현재 채팅방의 거래 요청 목록
  List<TradeRequest> _tradeRequests = [];
  
  // 거래 요청 목록 getter
  List<TradeRequest> get tradeRequests => List.unmodifiable(_tradeRequests);

  TradeManager() {
    // WebSocket 메시지 핸들러 등록
    _wsManager.addTradeRequestHandler(_handleNewTradeRequest);
    _wsManager.addTradeUpdateHandler(_handleTradeUpdate);
  }

  // WebSocket 채널 설정
  void setWebSocketChannel(WebSocketChannel? channel) {
    _wsManager.setChannel(channel);
  }

  // 거래 요청 목록 로드
  Future<void> loadTradeRequests(int roomId) async {
    try {
      final requests = await _tradeService.getTradeRequests(roomId);
      if (requests != null) {
        _tradeRequests = requests;
      } else {
        _tradeRequests = [];
      }
    } catch (e) {
      print('거래 요청 로드 실패: $e');
      _tradeRequests = [];
    }
  }

  // 새로운 거래 요청 처리
  void _handleNewTradeRequest(TradeRequest request) {
    // 중복 확인
    final existingIndex = _tradeRequests.indexWhere((r) => r.id == request.id);
    if (existingIndex == -1) {
      _tradeRequests.add(request);
    }
  }

  // 거래 상태 업데이트 처리
  void _handleTradeUpdate(TradeRequest updatedRequest) {
    final index = _tradeRequests.indexWhere((r) => r.id == updatedRequest.id);
    if (index != -1) {
      _tradeRequests[index] = updatedRequest;
    }
  }

  // 거래 요청 생성
  Future<void> createTradeRequest(
    int roomId,
    double proposedPrice,
    double proposedHours,
    String message,
  ) async {
    final request = CreateTradeRequest(
      proposedPrice: proposedPrice,
      proposedHours: proposedHours,
      message: message,
    );

    // WebSocket으로 실시간 전송
    _wsManager.sendTradeRequest(request);
  }

  // 거래 수락
  void acceptTrade(int tradeRequestId, {String? message}) {
    _wsManager.acceptTrade(tradeRequestId, message: message);
  }

  // 거래 거절
  void rejectTrade(int tradeRequestId, {String? message}) {
    _wsManager.rejectTrade(tradeRequestId, message: message);
  }

  // WebSocket 메시지 처리
  void handleWebSocketMessage(String message) {
    _wsManager.handleMessage(message);
  }

  // 핸들러 등록 메서드들
  void addTradeRequestHandler(Function(TradeRequest) handler) {
    _wsManager.addTradeRequestHandler(handler);
  }

  void addTradeUpdateHandler(Function(TradeRequest) handler) {
    _wsManager.addTradeUpdateHandler(handler);
  }

  void addErrorHandler(Function(String) handler) {
    _wsManager.addErrorHandler(handler);
  }

  // 특정 거래 요청 찾기
  TradeRequest? findTradeRequest(int tradeId) {
    try {
      return _tradeRequests.firstWhere((r) => r.id == tradeId);
    } catch (e) {
      return null;
    }
  }

  // 사용자별 거래 요청 필터링
  List<TradeRequest> getTradeRequestsForUser(int userId) {
    return _tradeRequests.where((r) => 
      r.requester.id == userId || r.receiver.id == userId
    ).toList();
  }

  // 대기중인 거래 요청만 필터링
  List<TradeRequest> getPendingTradeRequests() {
    return _tradeRequests.where((r) => r.isPending).toList();
  }

  // 완료된 거래 요청만 필터링
  List<TradeRequest> getCompletedTradeRequests() {
    return _tradeRequests.where((r) => r.isCompleted).toList();
  }

  // 정리
  void dispose() {
    _wsManager.dispose();
    _tradeRequests.clear();
  }
}
