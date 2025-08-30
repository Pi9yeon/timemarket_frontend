// lib/screens/chat_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timemarket_frontend/models/user_model.dart';
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
  List<dynamic> _chatRooms = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);

    final user = await _userService.getMyInfo();
    final rooms = await _chatService.getMyChatRooms();

    if (rooms != null) {
      rooms.sort((a, b) {
        final aTimestamp = a['last_message']?['timestamp'] ?? a['created_at'];
        final bTimestamp = b['last_message']?['timestamp'] ?? b['created_at'];
        return DateTime.parse(bTimestamp).compareTo(DateTime.parse(aTimestamp));
      });

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
      appBar: AppBar(title: const Text('대화 목록')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
              ? const Center(child: Text('대화 내역이 없습니다.'))
              : RefreshIndicator(
                onRefresh: _loadChatRooms,
                child: ListView.builder(
                  itemCount: _chatRooms.length,
                  itemBuilder: (context, index) {
                    final room = _chatRooms[index];
                    final otherUser = room['other_user'];
                    final lastMessage = room['last_message'];

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage:
                            otherUser?['profile_image'] != null
                                ? NetworkImage(otherUser['profile_image'])
                                : null,
                        child:
                            otherUser?['profile_image'] == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                      ),
                      title: Text(
                        otherUser?['nickname'] ?? '알 수 없는 사용자',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMessage?['message'] ?? '아직 메시지가 없습니다.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        lastMessage != null
                            ? DateFormat('HH:mm').format(
                              DateTime.parse(
                                lastMessage['timestamp'],
                              ).toLocal(),
                            )
                            : DateFormat('MM.dd').format(
                              DateTime.parse(room['created_at']).toLocal(),
                            ),
                      ),
                      onTap: () {
                        if (otherUser != null && _currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatScreen(
                                    roomId: room['id'],
                                    otherUserName: otherUser['nickname'],
                                    // ✅ 수정된 부분: 필수 파라미터인 currentUserId를 전달합니다.
                                    currentUserId: _currentUser!.id,
                                  ),
                            ),
                          ).then((_) => _loadChatRooms());
                        }
                      },
                    );
                  },
                ),
              ),
    );
  }
}
