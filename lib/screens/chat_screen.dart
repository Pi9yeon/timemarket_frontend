// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import '../models/post_model.dart'; // Post 모델 import

// 채팅 화면을 담당하는 StatefulWidget 입니다.
class ChatScreen extends StatefulWidget {
  // 게시물 정보를 받아와서 채팅방 상단에 제목 등을 표시할 수 있습니다.
  final Post post;

  const ChatScreen({super.key, required this.post});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 메시지 입력을 위한 컨트롤러
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ 백엔드 대신 사용할 '더미 데이터'입니다.
  final List<Map<String, dynamic>> _dummyMessages = [
    {
      'senderId': 'other_user', // 상대방 ID
      'text': '안녕하세요! 게시글 보고 연락드렸습니다.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      'senderId': 'current_user', // 현재 사용자 ID (나)
      'text': '네, 안녕하세요! 어떤 도움이 필요하신가요?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
    },
    {
      'senderId': 'other_user',
      'text': '1시간 정도 강아지 산책을 도와주실 수 있나요?',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 메시지를 전송하는 함수 (현재는 더미 데이터에 추가만 합니다)
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _dummyMessages.add({
        'senderId': 'current_user',
        'text': _messageController.text.trim(),
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
    });

    // 메시지 전송 후 스크롤을 맨 아래로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 게시글 작성자의 이름을 AppBar 제목으로 표시합니다.
        title: Text(widget.post.author.username),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // ✅ 채팅 화면 내 거래 버튼 (UI 프로토타입)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                // TODO: 거래 시작 로직 구현
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('거래 시작 기능 구현 예정')));
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('거래하기'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록을 표시하는 부분
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _dummyMessages.length,
              itemBuilder: (context, index) {
                final message = _dummyMessages[index];
                final isMe = message['senderId'] == 'current_user';
                return _buildMessageBubble(isMe, message['text']);
              },
            ),
          ),
          // 메시지 입력창을 표시하는 부분
          _buildMessageInput(),
        ],
      ),
    );
  }

  // 말풍선을 그리는 위젯
  Widget _buildMessageBubble(bool isMe, String text) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[200],
          borderRadius:
              isMe
                  ? const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  )
                  : const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // 메시지 입력창을 그리는 위젯
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
