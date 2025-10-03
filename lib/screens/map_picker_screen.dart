import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // 서울 시청을 기본 위치로 설정
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 16.0,
  );

  LatLng? _selectedPosition;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도에서 위치 선택'),
        actions: [
          // 위치가 선택되었을 때만 '선택' 버튼 활성화
          if (_selectedPosition != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // 선택된 위치(LatLng) 값을 이전 화면으로 반환
                Navigator.of(context).pop(_selectedPosition);
              },
            ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        // 지도를 탭했을 때 호출되는 콜백
        onTap: (LatLng position) {
          setState(() {
            _selectedPosition = position;
            _markers.clear(); // 기존 마커 제거
            _markers.add(
              Marker(
                markerId: const MarkerId('selected-location'),
                position: position,
              ),
            );
          });
        },
        markers: _markers,
      ),
    );
  }
}