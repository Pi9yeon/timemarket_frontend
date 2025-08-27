// lib/screens/post_detail_screen.dart

import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ✅ StatelessWidget을 StatefulWidget으로 변경하여 지도의 상태를 관리합니다.
class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // ✅ 지도의 전체 화면 모드 상태를 관리하는 변수입니다.
  bool _isMapFullscreen = false;

  Color _getBadgeColor(String type) {
    return type == 'sale' ? Colors.green : Colors.blue;
  }

  String _getBadgeText(String type) {
    return type == 'sale' ? '판매' : '구인';
  }

  // ✅ 전체 화면 모드를 토글하는 함수
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
    final postLocation = LatLng(widget.post.latitude, widget.post.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 상세'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        // ✅ 지도가 다른 위젯 위에 겹쳐 보이도록 Stack 위젯을 사용합니다.
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

                // ✅ 수정된 부분: 필요 시간, 작성자, 작성일 정보를 나란히 배치합니다.
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.access_time_outlined,
                        label: '필요 시간',
                        value: '${widget.post.price}',
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

                _buildLocationCard(postLocation, context),
              ],
            ),
          ),

          // ✅ 전체 화면 지도가 활성화되었을 때만 표시되는 위젯
          if (_isMapFullscreen)
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

  // ✅ _buildContentCard 헬퍼 위젯
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

  // ✅ _buildLocationCard 헬퍼 위젯
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

              // ✅ 지도를 Stack으로 감싸서 전체 화면 버튼을 겹쳐 올립니다.
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      child: _buildMapWidget(postLocation, false),
                    ),
                  ),
                  // ✅ 전체 화면 버튼
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

  // ✅ _buildMapWidget 헬퍼 위젯
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

  // ✅ _buildInfoCard 헬퍼 위젯
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

  // ✅ _buildInfoRow 헬퍼 위젯
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
}
