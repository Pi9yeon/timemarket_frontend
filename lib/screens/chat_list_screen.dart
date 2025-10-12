// lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timemarket_frontend/models/user_model.dart';
import 'package:timemarket_frontend/models/chat_room_model.dart';
import 'package:timemarket_frontend/services/user_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart'; // 실제 채팅 화면

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  // 화면이 다시 표시될 때마다 채팅 목록 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이미 한 번 로드된 경우에만 새로고침 (initState 중복 방지)
    if (mounted && _chatRooms.isNotEmpty) {
      _loadChatRooms();
    }
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);

    final user = await _userService.getMyInfo();
    final rooms = await _chatService.getMyChatRooms();

    print('🔍 ChatListScreen - 로드된 채팅방 개수: ${rooms?.length}'); // 디버그 출력

    if (rooms != null) {
      // 각 채팅방의 Post 정보 확인
      for (int i = 0; i < rooms.length; i++) {
        final room = rooms[i];
        print('🔍 채팅방 $i - ID: ${room.id}, Post 존재: ${room.post != null}');
        if (room.post != null) {
          print('🔍   Post 제목: ${room.post!.title}');
          print('🔍   Post 타입: ${room.post!.type}');
          print('🔍   Post 가격: ${room.post!.price}');
        }
      }

      // 최신 순으로 정렬 (생성 시간 기준)
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _chatRooms = rooms;
        _currentUser = user;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      indent: 72,
                      color: Color(0xFFE5E5E5),
                    ),
                    itemBuilder: (context, index) {
                      final room = _chatRooms[index];
                      final otherUser = room.getOtherUser(_currentUser?.id ?? 0);
                      
                      return _buildChatRoomItem(room, otherUser);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '아직 채팅 내역이 없어요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '시간 거래를 시작해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room, User? otherUser) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          if (otherUser != null && _currentUser != null) {
            print('🔍 채팅방 이동 - Room ID: ${room.id}');
            print('🔍 전달할 Post: ${room.post}');
            print('🔍 Post null 여부: ${room.post == null}');
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  roomId: room.id,
                  otherUserName: otherUser.username,
                  currentUserId: _currentUser!.id,
                  post: room.post, // 게시글 정보 전달
                ),
              ),
            ).then((_) => _loadChatRooms());
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 프로필 이미지
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: otherUser?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          otherUser!.profileImageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, color: Colors.grey[400]),
                        ),
                      )
                    : Icon(Icons.person, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              
              // 채팅 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상단: 닉네임과 시간
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          otherUser?.username ?? '알 수 없는 사용자',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('MM.dd').format(room.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 게시글 정보
                    if (room.post != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: room.post!.type == 'sale' 
                              ? const Color(0xFFF0F8FF) 
                              : const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: room.post!.type == 'sale'
                                ? const Color(0xFF4A90E2)
                                : const Color(0xFFFF8C00),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              room.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: room.post!.type == 'sale'
                                    ? const Color(0xFF4A90E2)
                                    : const Color(0xFFFF8C00),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              room.priceText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: room.post!.type == 'sale'
                                    ? const Color(0xFF4A90E2)
                                    : const Color(0xFFFF8C00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // 게시글 제목
                      Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      // 게시글 정보가 없을 때
                      Text(
                        '일반 채팅',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
