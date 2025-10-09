// lib/models/trade_model.dart

import 'user_model.dart';
import 'post_model.dart';

class TradeRequest {
  final int id;
  final int room;
  final Post post;
  final User requester;
  final User receiver;
  final double proposedPrice;
  final double proposedHours;
  final String message;
  final String status;
  final bool requesterAccepted;
  final bool receiverAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TradeRequest({
    required this.id,
    required this.room,
    required this.post,
    required this.requester,
    required this.receiver,
    required this.proposedPrice,
    required this.proposedHours,
    required this.message,
    required this.status,
    required this.requesterAccepted,
    required this.receiverAccepted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TradeRequest.fromJson(Map<String, dynamic> json) {
    return TradeRequest(
      id: json['id'],
      room: json['room'],
      post: Post.fromJson(json['post']),
      requester: User.fromJson(json['requester']),
      receiver: User.fromJson(json['receiver']),
      proposedPrice: double.parse(json['proposed_price'].toString()),
      proposedHours: double.parse(json['proposed_hours'].toString()),
      message: json['message'] ?? '',
      status: json['status'],
      requesterAccepted: json['requester_accepted'] ?? false,
      receiverAccepted: json['receiver_accepted'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room': room,
      'post': post.toJson(),
      'requester': requester.toJson(),
      'receiver': receiver.toJson(),
      'proposed_price': proposedPrice,
      'proposed_hours': proposedHours,
      'message': message,
      'status': status,
      'requester_accepted': requesterAccepted,
      'receiver_accepted': receiverAccepted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 거래 상태 확인 메서드들
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  // 사용자별 수락 여부 확인
  bool isAcceptedByUser(int userId) {
    if (userId == requester.id) {
      return requesterAccepted;
    } else if (userId == receiver.id) {
      return receiverAccepted;
    }
    return false;
  }

  // 사용자가 응답할 수 있는지 확인
  bool canUserRespond(int userId) {
    return isPending && (userId == requester.id || userId == receiver.id);
  }

  // 거래 완료 조건 확인
  bool get canBeCompleted => requesterAccepted && receiverAccepted;

  // 가격 포맷팅
  String get formattedPrice {
    return '${proposedPrice.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  // 시간 포맷팅
  String get formattedHours {
    if (proposedHours == proposedHours.toInt()) {
      return '${proposedHours.toInt()}시간';
    } else {
      return '$proposedHours시간';
    }
  }

  // 상태 텍스트
  String get statusText {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'completed':
        return '거래 완료';
      case 'rejected':
        return '거래 거절';
      case 'cancelled':
        return '거래 취소';
      default:
        return '알 수 없음';
    }
  }

  // 상태별 색상
  String get statusColor {
    switch (status) {
      case 'pending':
        return '#FFA500'; // 주황색
      case 'completed':
        return '#4CAF50'; // 초록색
      case 'rejected':
        return '#F44336'; // 빨간색
      case 'cancelled':
        return '#9E9E9E'; // 회색
      default:
        return '#9E9E9E';
    }
  }

  // 복사 생성자 (상태 업데이트용)
  TradeRequest copyWith({
    int? id,
    int? room,
    Post? post,
    User? requester,
    User? receiver,
    double? proposedPrice,
    double? proposedHours,
    String? message,
    String? status,
    bool? requesterAccepted,
    bool? receiverAccepted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradeRequest(
      id: id ?? this.id,
      room: room ?? this.room,
      post: post ?? this.post,
      requester: requester ?? this.requester,
      receiver: receiver ?? this.receiver,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      proposedHours: proposedHours ?? this.proposedHours,
      message: message ?? this.message,
      status: status ?? this.status,
      requesterAccepted: requesterAccepted ?? this.requesterAccepted,
      receiverAccepted: receiverAccepted ?? this.receiverAccepted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// WebSocket 메시지 타입들
class TradeMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String? message;
  final bool? isCompleted;

  TradeMessage({
    required this.type,
    this.data,
    this.message,
    this.isCompleted,
  });

  factory TradeMessage.fromJson(Map<String, dynamic> json) {
    return TradeMessage(
      type: json['type'],
      data: json['data'],
      message: json['message'],
      isCompleted: json['is_completed'],
    );
  }

  // 채팅 메시지인지 확인
  bool get isChatMessage => type == 'chat_message';
  
  // 거래 요청인지 확인
  bool get isTradeRequest => type == 'trade_request';
  
  // 거래 상태 업데이트인지 확인
  bool get isTradeStatusUpdate => type == 'trade_status_update';
  
  // 에러 메시지인지 확인
  bool get isError => type == 'error';
}

// 거래 요청 생성용 모델
class CreateTradeRequest {
  final double proposedPrice;
  final double proposedHours;
  final String message;

  CreateTradeRequest({
    required this.proposedPrice,
    required this.proposedHours,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'trade_request',
      'proposed_price': proposedPrice,
      'proposed_hours': proposedHours,
      'message': message,
    };
  }
}

// 거래 응답용 모델
class TradeResponse {
  final int tradeRequestId;
  final String response; // 'accept' or 'reject'
  final String? message;

  TradeResponse({
    required this.tradeRequestId,
    required this.response,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': 'trade_response',
      'trade_request_id': tradeRequestId,
      'response': response,
      if (message != null) 'message': message,
    };
  }

  // 수락 응답 생성
  factory TradeResponse.accept(int tradeRequestId, {String? message}) {
    return TradeResponse(
      tradeRequestId: tradeRequestId,
      response: 'accept',
      message: message,
    );
  }

  // 거절 응답 생성
  factory TradeResponse.reject(int tradeRequestId, {String? message}) {
    return TradeResponse(
      tradeRequestId: tradeRequestId,
      response: 'reject',
      message: message,
    );
  }
}
