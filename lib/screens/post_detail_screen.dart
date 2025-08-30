// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart'; // ✅ 1단계: 아래 3개의 import를 잠시 주석 처리합니다.
import '../services/chat_service.dart';
import '../services/user_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ChatService _chatService = ChatService(); // ✅ 2단계: 서비스 인스턴스도 주석 처리합니다.
  final UserService _userService = UserService();
  bool _isMapFullscreen = false;
  bool _isChatButtonLoading = false; // ✅ 3단계: 버튼 로딩 상태도 주석 처리합니다.

  Color _getBadgeColor(String type) {
    return type == 'sale' ? Colors.green : Colors.blue;
  }

  String _getBadgeText(String type) {
    return type == 'sale' ? '판매' : '구인';
  }

  void _toggleFullscreen() {
    setState(() {
      _isMapFullscreen = !_isMapFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'yyyy.MM.dd HH:mm',
    ).format(widget.post.createdAt);

    final lat = widget.post.latitude;
    final lng = widget.post.longitude;
    final bool isLocationValid =
        (lat >= -90 && lat <= 90) && (lng >= -180 && lng <= 180);
    final LatLng? postLocation = isLocationValid ? LatLng(lat, lng) : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildChatButton(), // ✅ 4단계: 채팅 버튼 호출 부분을 주석 처리합니다.
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.post.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(widget.post.type),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _getBadgeText(widget.post.type),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.access_time_outlined,
                        label: '필요 시간',
                        value: '${widget.post.price} TC',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.person_outline,
                        label: '작성자',
                        value: widget.post.author.username,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.date_range_outlined,
                        label: '작성일',
                        value: formattedDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildContentCard(widget.post.description),
                const SizedBox(height: 16),
                if (postLocation != null)
                  _buildLocationCard(postLocation, context)
                else
                  _buildInvalidLocationCard(),
              ],
            ),
          ),
          if (_isMapFullscreen && postLocation != null)
            GestureDetector(
              onTap: _toggleFullscreen,
              child: Container(
                color: Colors.black.withOpacity(0.8),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: _buildMapWidget(postLocation, true),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // lib/screens/post_detail_screen.dart의 _PostDetailScreenState 클래스 내부

  Widget _buildChatButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          icon:
              _isChatButtonLoading
                  ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                  : const Icon(Icons.chat_bubble_outline),
          label: const Text('채팅하기'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          onPressed:
              _isChatButtonLoading
                  ? null
                  : () async {
                    setState(() => _isChatButtonLoading = true);

                    // ✅ 수정: chatService를 호출할 때 게시글 작성자의 ID를 receiverId로 함께 전달합니다.
                    final roomData = await _chatService.createOrGetChatRoom(
                      widget.post.id,
                      widget.post.author.id, // 상대방(게시글 작성자) ID
                    );

                    final currentUser = await _userService.getMyInfo();

                    if (roomData != null && currentUser != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatScreen(
                                roomId: roomData['id'],
                                otherUserName: widget.post.author.username,
                              ),
                        ),
                      );
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('채팅방을 열 수 없습니다.')),
                        );
                      }
                    }

                    setState(() => _isChatButtonLoading = false);
                  },
        ),
      ),
    );
  }

  Widget _buildContentCard(String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "내용",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(LatLng postLocation, BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                label: '위치',
                value:
                    '위도: ${postLocation.latitude.toStringAsFixed(4)}, 경도: ${postLocation.longitude.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: _buildMapWidget(postLocation, false),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.all(4),
                        minimumSize: Size.zero,
                      ),
                      onPressed: _toggleFullscreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapWidget(LatLng location, bool isFullscreen) {
    return FlutterMap(
      options: MapOptions(
        center: location,
        zoom: isFullscreen ? 14.0 : 16.0,
        interactiveFlags:
            isFullscreen ? InteractiveFlag.all : InteractiveFlag.none,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(
          markers: [
            Marker(
              width: 80,
              height: 80,
              point: location,
              builder:
                  (ctx) => const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildInfoRow(icon: icon, label: label, value: value),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.location_off_outlined, color: Colors.red, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '유효하지 않은 위치 정보입니다.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
