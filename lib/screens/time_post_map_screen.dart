// lib/screens/time_post_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/time_post_service.dart';
import '../services/auth_service.dart';
import 'time_post_list_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

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
  final String _postType = 'sale'; // 기본: 판매 목록

  final LatLng _initialCenter = LatLng(37.5665, 126.9780); // 서울 시청 좌표
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

    if (posts != null) {
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Marker> _buildMarkers() {
    return _posts
        .where((post) {
          final lat = post['latitude'] as double;
          final lng = post['longitude'] as double;

          if (lat < -90 || lat > 90) return false;
          if (lng < -180 || lng > 180) return false;

          return true;
        })
        .map((post) {
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
                    showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text(title),
                            content: Text('위도: $lat\n경도: $lng'),
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
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TimeMarket',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: Colors.white),
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
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: '마이 페이지',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: '로그아웃',
            onPressed: () async {
              await _authService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
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
