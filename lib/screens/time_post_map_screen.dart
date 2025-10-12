// lib/screens/time_post_map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/time_post_service.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';

class TimePostMapScreen extends StatefulWidget {
  const TimePostMapScreen({super.key});

  @override
  State<TimePostMapScreen> createState() => _TimePostMapScreenState();
}

class _TimePostMapScreenState extends State<TimePostMapScreen>
    with AutomaticKeepAliveClientMixin {
  final TimePostService _postService = TimePostService();
  List<dynamic> _posts = [];
  bool _loading = true;
  final String? _postType = null; // null로 설정하여 모든 타입(판매, 구인) 표시

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Position? _currentPosition;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 16.0,
  );

  @override
  bool get wantKeepAlive => false; // 화면 재진입 시마다 새로고침

  @override
  void initState() {
    super.initState();
    // 위젯이 완전히 빌드된 후에 현재 위치를 가져오고 데이터 로드
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      await _loadNearbyPosts();
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // 지도가 로드될 시간을 줍니다
      if (mounted) {
        await _determinePositionAndCenter();
      }
    } catch (e) {
      print('초기 데이터 로딩 중 오류 발생: $e');
    }
  }

  Future<void> _determinePositionAndCenter() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 사용 가능 여부 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 위치 서비스가 꺼져 있으면 사용자에게 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다. 위치를 활성화해주세요.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 변경하세요.'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      try {
        final controller = await _controller.future;
        final target = LatLng(position.latitude, position.longitude);
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16.0),
          ),
        );
      } catch (e) {
        print('카메라 이동 중 오류 발생: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('현재 위치로 이동하는데 실패했습니다.')));
        }
      }
    } catch (e) {
      print('위치 가져오기 실패: $e');
    }
  }

  // 화면이 다시 표시될 때마다 데이터 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted && _posts.isNotEmpty) {
      _loadNearbyPosts();
    }
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

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    for (final post in _posts) {
      try {
        final lat = (post['latitude'] as num).toDouble();
        final lng = (post['longitude'] as num).toDouble();
        final title = post['title'] as String? ?? '제목 없음';
        final price = post['price'] as int? ?? 0;
        final type = post['type'] as String? ?? 'sale';
        final String markerId =
            post['id']?.toString() ?? 'marker_${markers.length}';
        final authorName = post['user']?['username'] as String? ?? '알 수 없음';

        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          print('잘못된 좌표값으로 인해 마커를 건너뜁니다: 위도=$lat, 경도=$lng');
          continue;
        }

        // 게시글 타입에 따른 마커 색상 설정
        BitmapDescriptor markerIcon =
            type == 'sale'
                ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                )
                : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                );

        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: LatLng(lat, lng),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: title,
              snippet:
                  '${type == 'sale' ? '판매' : '구인'} • ${price}TC • $authorName',
            ),
            onTap: () {
              print('마커 클릭됨: $title (ID: $markerId)');
              // 마커 클릭 시 게시글 상세 페이지로 이동
              _navigateToPostDetail(post);
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

  // 게시글 상세 페이지로 이동하는 함수
  void _navigateToPostDetail(dynamic postData) {
    try {
      // 동적 데이터를 Post 모델로 변환
      final post = Post.fromJson(postData);

      // MainScreen의 컨텍스트를 찾아서 네비게이션 실행
      final navigator = Navigator.of(context, rootNavigator: true);
      navigator.push(
        MaterialPageRoute(builder: (context) => PostDetailScreen(post: post)),
      );
    } catch (e) {
      print('게시글 상세 페이지 이동 중 오류 발생: $e');
      print('게시글 데이터: $postData');

      // 에러 메시지도 rootNavigator 사용
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시글을 불러올 수 없습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6F00)),
              ),
              SizedBox(height: 16),
              Text(
                '지도를 불러오는 중...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    try {
      // GoogleMap을 Scaffold로 감싸서 FAB 등 UI를 추가할 수 있게 함
      return Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialCamera,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              markers: _buildMarkers(),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              padding: const EdgeInsets.only(bottom: 80, left: 15),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 72.0), // 작성 버튼과 겹치지 않도록 여유
          child: FloatingActionButton(
            onPressed: _goToCurrentLocation,
            backgroundColor: const Color(0xFFFF6F00),
            child: const Icon(Icons.my_location),
            tooltip: '현재 위치로 이동',
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      );
    } catch (e) {
      print('Google Maps 로딩 오류: $e');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '지도를 불러올 수 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '페이지를 새로고침해주세요',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      // 재사용 가능한 캐시된 위치가 있으면 우선 사용
      Position? pos = _currentPosition;
      if (pos == null) {
        // 권한 & 서비스 처리는 _determinePositionAndCenter에서 이미 처리되므로
        // 여기서는 단순히 현재 위치를 요청
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = pos;
      }

      if (!mounted) return;

      final controller = await _controller.future;
      final target = LatLng(pos.latitude, pos.longitude);
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.0),
        ),
      );
    } catch (e) {
      print('현재 위치로 이동 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현재 위치로 이동하는 데 실패했습니다.')));
      }
    }
  }


}
