// lib/screens/chat_screen.dart
import 'dart:convert'; // ✅ JSON 인코딩/디코딩을 위해 필요
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // ✅ 웹소켓 채널 사용
import '../services/chat_service.dart';
import '../services/user_service.dart'; // ✅ 현재 사용자 ID를 가져오기 위함

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel; // ✅ 메시지를 주고받을 통신 채널
  int? _currentUserId; // ✅ 내가 보낸 메시지인지 구분하기 위한 ID

  @override
  void initState() {
    super.initState();
    _connectToChat();
  }

  // 채팅 서버에 연결하는 함수
  Future<void> _connectToChat() async {
    // 현재 로그인한 사용자의 ID를 가져옵니다.
    final user = await UserService().getMyInfo();
    if (user == null) return;
    _currentUserId = user.id;

    // ChatService를 통해 웹소켓 채널에 연결합니다.
    final channel = await _chatService.connect(widget.roomId);
    setState(() {
      _channel = channel;
    });
  }

  // 메시지를 웹소켓 채널로 전송하는 함수
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _channel == null) return;

    // 백엔드에서 받을 JSON 형식에 맞춰 메시지를 구성하고 전송합니다.
    final message = {'message': _messageController.text.trim()};
    _channel!.sink.add(jsonEncode(message));

    _messageController.clear();
  }

  @override
  void dispose() {
    // ✅ 화면이 종료될 때 웹소켓 연결을 반드시 끊어줘야 합니다. (중요!)
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        // ... (이전 AppBar 스타일과 동일)
      ),
      body: Column(
        children: [
          Expanded(
            // ✅ StreamBuilder: 웹소켓 채널(stream)을 계속 듣고 있다가,
            // 새로운 데이터가 들어올 때마다 화면을 자동으로 다시 그려주는 위젯입니다.
            child: StreamBuilder(
              stream: _channel?.stream,
              builder: (context, snapshot) {
                // 연결 중이거나, 채널이 아직 준비되지 않았을 때 로딩 표시
                if (snapshot.connectionState == ConnectionState.waiting ||
                    _channel == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                // 에러 발생 시 에러 메시지 표시
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                // 데이터가 없을 때 (아직 메시지가 없을 때)
                if (!snapshot.hasData) {
                  return const Center(child: Text('채팅을 시작해보세요!'));
                }

                // ✅ 백엔드에서 받은 메시지 목록 (JSON 문자열 리스트)
                final messages =
                    jsonDecode(snapshot.data as String)['messages'] as List;

                // 메시지를 화면에 그립니다.
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['sender']['id'] == _currentUserId;
                    return _buildMessageBubble(isMe, message['message']);
                  },
                );
              },
            ),
          ),
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
