// lib/screens/chat_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int roomId;
  final String otherUserName;
  final int currentUserId;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final messageHistory = await _chatService.getMessages(widget.roomId);
    if (messageHistory != null) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(messageHistory);
        _isLoading = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isLoading = false);
    }

    _channel = await _chatService.connect(widget.roomId);

    _channel?.stream.listen((message) {
      // ✅ 백엔드에서 오는 데이터는 이제 항상 일관된 JSON 형식이므로 그대로 디코딩합니다.
      final newMessage = jsonDecode(message);

      // 중복 메시지 방지 (이미 목록에 있는 메시지인지 확인)
      bool isDuplicate = _messages.any((m) => m['id'] == newMessage['id']);
      if (!isDuplicate) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _channel == null) return;

    final message = {'message': _messageController.text.trim()};
    _channel!.sink.add(jsonEncode(message));

    _messageController.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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
        title: Text(widget.otherUserName),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        // ✅ 'sender'는 이제 항상 Map 형태이므로 안전하게 id를 가져올 수 있습니다.
                        final isMe =
                            message['sender']['id'] == widget.currentUserId;
                        return _buildMessageBubble(isMe, message['message']);
                      },
                    ),
                  ),
                  _buildMessageInput(),
                ],
              ),
    );
  }

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
