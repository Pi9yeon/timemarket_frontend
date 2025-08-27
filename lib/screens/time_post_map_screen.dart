// lib/screens/time_post_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/auth_service.dart';
import '../services/time_post_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'time_post_list_screen.dart';

class TimePostMapScreen extends StatefulWidget {
  const TimePostMapScreen({super.key});

  @override
  State<TimePostMapScreen> createState() => _TimePostMapScreenState();
}

class _TimePostMapScreenState extends State<TimePostMapScreen> {
  final TimePostService _postService = TimePostService();
  final AuthService _authService = AuthService();
  List<dynamic> _posts = [];
  bool _loading = true;
  final String _postType = 'sale';

  final LatLng _initialCenter = LatLng(37.5665, 126.9780);
  final double _zoom = 16;

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    final posts = await _postService.fetchNearbyPosts(
      lat: _initialCenter.latitude,
      lng: _initialCenter.longitude,
      type: _postType,
    );
    if (mounted) {
      setState(() {
        _posts = posts ?? [];
        _loading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    return _posts.map((post) {
      final lat = post['latitude'] as double;
      final lng = post['longitude'] as double;
      final title = post['title'] as String? ?? '제목 없음';

      return Marker(
        width: 80,
        height: 80,
        point: LatLng(lat, lng),
        builder:
            (ctx) => GestureDetector(
              onTap: () {
                // ✅ 수정된 부분: 주석을 올바르게 닫고, 내용을 다이얼로그로 옮겼습니다.
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text(title),
                        content: Text('상세 내용을 보시겠습니까?'), // 예시 내용
                        actions: [
                          TextButton(
                            child: const Text('닫기'),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                );
              },
              child: const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            ),
      );
    }).toList(); // ✅ .map()의 결과를 .toList()로 변환하여 반환 타입을 일치시켰습니다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TimeMarket'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '게시글 목록',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimePostListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: '마이 페이지',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                options: MapOptions(center: _initialCenter, zoom: _zoom),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
    );
  }
}
