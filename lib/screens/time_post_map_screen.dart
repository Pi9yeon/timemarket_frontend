// lib/screens/time_post_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../services/time_post_service.dart';
import 'create_post_screen.dart'; // CreatePostScreen 임포트
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

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    _loadNearbyPosts();
  }

  Future<void> _loadNearbyPosts() async {
    // 서버 통신 중에는 로딩 상태로 표시
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }
    
    final posts = await _postService.fetchNearbyPosts(
      lat: _initialCamera.target.latitude,
      lng: _initialCamera.target.longitude,
      type: _postType,
    );
    if (mounted) {
      setState(() {
        _posts = posts ?? [];
        _loading = false;
      });
    }
  }

  // ✅ 1. 글 작성 화면으로 이동하고, 돌아왔을 때 새로고침하는 함수
  Future<void> _navigateAndRefresh() async {
    // CreatePostScreen으로 이동하고, 결과가 돌아올 때까지 기다립니다.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );

    // 만약 CreatePostScreen에서 true를 반환했다면 (성공적으로 글을 작성했다면)
    if (result == true && mounted) {
      // 게시물 데이터를 다시 불러옵니다.
      _loadNearbyPosts();
    }
  }

  Set<Marker> _buildMarkers() {
    // ... (_buildMarkers 함수는 변경 없음) ...
    final Set<Marker> markers = {};

    for (final post in _posts) {
      try {
        final lat = (post['latitude'] as num).toDouble();
        final lng = (post['longitude'] as num).toDouble();
        final title = post['title'] as String? ?? '제목 없음';
        final String markerId = post['id']?.toString() ?? 'marker_${markers.length}';

        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          print('잘못된 좌표값으로 인해 마커를 건너뜁니다: 위도=$lat, 경도=$lng');
          continue;
        }

        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: LatLng(lat, lng),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
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
          ),
        );
      } catch (e) {
        print('게시물 데이터 처리 중 오류 발생: $post, 오류: $e');
        continue;
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ... (AppBar 코드는 변경 없음) ...
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: _buildMarkers(),
            ),
      // ✅ 2. 글 작성 화면으로 이동하는 FloatingActionButton 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh, // 위에서 만든 함수를 연결
        tooltip: '게시글 작성',
        child: const Icon(Icons.add),
      ),
    );
  }
}