// lib/models/chat_room_model.dart

import 'post_model.dart';
import 'user_model.dart';

// 메시지 모델 추가
class Message {
  final int id;
  final int room;
  final User sender;
  final int receiver;
  final String message;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.room,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      room: json['room'],
      sender: User.fromJson(json['sender']),
      receiver: json['receiver'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatRoom {
  final int id;
  final Post? post; // null 허용으로 변경
  final User? otherUser; // users 배열 대신 other_user 단일 객체
  final Message? lastMessage; // 마지막 메시지 추가
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    this.post, // required 제거
    this.otherUser,
    this.lastMessage,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    print('🔍 ChatRoom.fromJson - 입력 데이터: $json'); // 디버그 출력
    print('🔍 Post 데이터: ${json['post']}'); // 디버그 출력
    print('🔍 Other User 데이터: ${json['other_user']}'); // 디버그 출력
    print('🔍 Last Message 데이터: ${json['last_message']}'); // 디버그 출력
    
    return ChatRoom(
      id: json['id'],
      post: json['post'] != null ? Post.fromJson(json['post']) : null,
      otherUser: json['other_user'] != null 
          ? User.fromJson(json['other_user']) 
          : null,
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // 현재 사용자를 제외한 다른 사용자 반환 (수정됨)
  User? getOtherUser(int currentUserId) {
    // otherUser가 현재 사용자와 다른 경우 반환
    if (otherUser != null && otherUser!.id != currentUserId) {
      return otherUser;
    }
    return null;
  }

  // 채팅방 제목 생성 (게시글 제목 기반)
  String get title => post?.title ?? '일반 채팅';

  // 채팅방 설명 생성 (게시글 설명 기반)
  String get description => post?.description ?? '채팅방';

  // 가격 정보
  String get priceText => post != null 
    ? '${post!.price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}원'
    : '가격 정보 없음';

  // 게시글 타입에 따른 라벨
  String get typeLabel => post?.type == 'sale' ? '판매' : '구매';

  // 마지막 메시지 텍스트 (새로 추가)
  String get lastMessageText => lastMessage?.message ?? '메시지 없음';

  // 마지막 메시지 시간 (새로 추가)
  String get lastMessageTime {
    if (lastMessage == null) return '';
    
    final now = DateTime.now();
    final messageTime = lastMessage!.timestamp;
    final difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
