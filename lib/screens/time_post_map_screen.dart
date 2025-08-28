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

  // lib/screens/time_post_map_screen.dart

  // ✅ 1. 기존 .where().map() 구조를 for 반복문으로 변경하여 안정성 강화
  List<Marker> _buildMarkers() {
    // 반환할 마커들을 담을 빈 리스트를 생성합니다.
    final List<Marker> markers = [];

    // 백엔드에서 받아온 모든 게시물을 하나씩 확인합니다.
    for (final post in _posts) {
      try {
        // ✅ 2. num 타입으로 유연하게 받고 toDouble()으로 변환하여 안정성 확보
        final lat = (post['latitude'] as num).toDouble();
        final lng = (post['longitude'] as num).toDouble();
        final title = post['title'] as String? ?? '제목 없음';

        // ✅ 3. Marker를 생성하기 전에 위도와 경도 값의 유효 범위를 직접 확인합니다.
        // 범위를 벗어나는 데이터는 마커로 만들지 않고 건너뜁니다.
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          // 콘솔에 어떤 데이터가 잘못되었는지 로그를 남겨서 디버깅을 돕습니다.
          print('잘못된 좌표값으로 인해 마커를 건너뜁니다: 위도=$lat, 경도=$lng');
          continue; // 다음 게시물로 넘어갑니다.
        }

        // 유효한 좌표값을 가진 게시물만 마커로 만들어 리스트에 추가합니다.
        markers.add(
          Marker(
            width: 80,
            height: 80,
            point: LatLng(lat, lng), // 이제 이 코드는 유효한 값만 받게 됩니다.
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
          ),
        );
      } catch (e) {
        // 숫자 변환 오류 등 예기치 않은 에러가 발생해도 앱이 멈추지 않도록 처리합니다.
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
