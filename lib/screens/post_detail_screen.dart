// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isCurrentUserAuthor = false;

  // 당근마켓 스타일의 컬러 테마
  static const Color carrotOrange = Color(0xFFFF6F00);

  @override
  void initState() {
    super.initState();
    _checkIfCurrentUserIsAuthor();
  }

  Future<void> _checkIfCurrentUserIsAuthor() async {
    final currentUser = await _userService.getMyInfo();
    if (currentUser != null) {
      setState(() {
        _isCurrentUserAuthor = currentUser.id == widget.post.author.id;
      });
    }
  }

  Color _getBadgeColor(String type) {
    return type == 'sale' ? const Color(0xFF4A90E2) : const Color(0xFFFF8C00);
  }

  String _getBadgeText(String type) {
    return type == 'sale' ? '판매' : '구매';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '게시글 상세',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: _isCurrentUserAuthor ? null : _buildChatButton(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 및 배지 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getBadgeColor(widget.post.type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getBadgeColor(widget.post.type),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _getBadgeText(widget.post.type),
                              style: TextStyle(
                                color: _getBadgeColor(widget.post.type),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.post.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 정보 카드들
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        icon: Icons.access_time_outlined,
                        label: '필요 시간',
                        value: '${widget.post.price} TC',
                        iconColor: carrotOrange,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 16),
                      _buildAuthorRow(),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[200], height: 1),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: '작성일',
                        value: formattedDate,
                        iconColor: Colors.grey[700]!,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildContentCard(widget.post.description),
                const SizedBox(height: 12),
                if (postLocation != null)
                  _buildLocationCard(postLocation, context)
                else
                  _buildInvalidLocationCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isMapFullscreen && postLocation != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _toggleFullscreen();
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.92,
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: _buildMapWidget(postLocation, true),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: 20,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _toggleFullscreen();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: carrotOrange,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
          ),
          onPressed:
              _isChatButtonLoading
                  ? null
                  : () async {
                    HapticFeedback.lightImpact();
                    setState(() => _isChatButtonLoading = true);

                    final roomData = await _chatService.createOrGetChatRoom(
                      widget.post.id,
                      widget.post.author.id,
                    );

                    final currentUser = await _userService.getMyInfo();

                    if (roomData != null && currentUser != null && mounted) {
                      // 채팅 화면으로 이동하고, 돌아왔을 때 true 반환
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatScreen(
                                roomId: roomData['id'],
                                otherUserName: widget.post.author.username,
                                currentUserId: currentUser.id,
                                post: widget.post, // 게시글 정보 전달 추가
                              ),
                        ),
                      );
                      
                      // 채팅방을 생성했으므로, PostDetailScreen을 닫으면서 true 반환
                      // 이를 통해 이전 화면에서 필요한 경우 새로고침 가능
                      if (mounted && result != null) {
                        // 채팅 생성 성공을 알림
                        Navigator.pop(context, true);
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('채팅방을 열 수 없습니다.')),
                        );
                      }
                    }

                    setState(() => _isChatButtonLoading = false);
                  },
          child: _isChatButtonLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 8),
                    const Text('채팅하기'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContentCard(String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "상세 내용",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LatLng postLocation, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Colors.red[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "위치 정보",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '위도: ${postLocation.latitude.toStringAsFixed(4)}, 경도: ${postLocation.longitude.toStringAsFixed(4)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
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
                bottom: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _toggleFullscreen();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.grey[800],
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildAuthorRow() {
    // 디버깅: 작성자 프로필 이미지 URL 확인
    print('📸 [게시글 상세] 작성자 정보:');
    print('   - 이름: ${widget.post.author.username}');
    print('   - ID: ${widget.post.author.id}');
    print('   - 프로필 이미지 URL: ${widget.post.author.profileImageUrl ?? "null"}');
    
    return Row(
      children: [
        // 작성자 프로필 이미지
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[200],
          backgroundImage: widget.post.author.profileImageUrl != null
              ? NetworkImage(widget.post.author.profileImageUrl!)
              : null,
          child: widget.post.author.profileImageUrl == null
              ? Icon(
                  Icons.person,
                  size: 24,
                  color: Colors.grey[600],
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '작성자',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.post.author.username,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? carrotOrange).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor ?? carrotOrange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '유효하지 않은 위치 정보입니다.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}