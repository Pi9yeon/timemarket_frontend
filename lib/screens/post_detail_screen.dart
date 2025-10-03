// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
// ✅ google_maps_flutter 패키지 및 LatLng 클래스 임포트
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/post_model.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';
import 'chat_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  bool _isMapFullscreen = false;
  bool _isChatButtonLoading = false;

  // ... (다른 함수들은 변경 없음) ...
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
    // ✅ latlong2 대신 google_maps_flutter의 LatLng를 사용
    final LatLng? postLocation = isLocationValid ? LatLng(lat, lng) : null;

    // ... (Scaffold 및 나머지 build 메소드 구조는 거의 동일) ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildChatButton(),
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
                const SizedBox(height: 80),
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

  // ... (_buildChatButton, _buildContentCard 등 다른 위젯 빌더는 변경 없음) ...
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

                    final roomData = await _chatService.createOrGetChatRoom(
                      widget.post.id,
                      widget.post.author.id,
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
                                currentUserId: currentUser.id,
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

  // ✅ 변경: FlutterMap 대신 GoogleMap을 사용하도록 위젯 수정
  Widget _buildMapWidget(LatLng location, bool isFullscreen) {
    return GoogleMap(
      // 지도 초기 카메라 위치 설정
      initialCameraPosition: CameraPosition(
        target: location,
        zoom: isFullscreen ? 14.0 : 16.0,
      ),
      // 지도에 표시할 마커 설정
      markers: {
        Marker(
          markerId: const MarkerId('postLocation'), // 마커의 고유 ID
          position: location, // 마커의 위치
        ),
      },
      // 전체 화면이 아닐 때는 지도 상호작용 비활성화
      zoomGesturesEnabled: isFullscreen,
      scrollGesturesEnabled: isFullscreen,
      tiltGesturesEnabled: isFullscreen,
      rotateGesturesEnabled: isFullscreen,
      // 지도 하단의 Google 로고나 컨트롤 버튼 제거
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }

  // ... (나머지 _buildInfoCard, _buildInfoRow, _buildInvalidLocationCard 함수는 변경 없음) ...
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