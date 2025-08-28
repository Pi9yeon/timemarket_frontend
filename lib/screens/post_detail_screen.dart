// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart'; // ✅ 1. chat_screen.dart를 import 합니다.

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isMapFullscreen = false;

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
                // ✅ 채팅 버튼을 bottomNavigationBar로 옮겼으므로 하단 공간 확보
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

  // 채팅하기 버튼 UI를 생성하는 헬퍼 위젯
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
          icon: const Icon(Icons.chat_bubble_outline),
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
          onPressed: () {
            // ✅ 2. 버튼 클릭 시 ChatScreen으로 이동하도록 로직을 수정합니다.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(post: widget.post)),
            );
          },
        ),
      ),
    );
  }

  // (이하 다른 헬퍼 위젯들은 변경 없음)

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
          padding: EdgeInsets.all(16.0),
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
