import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // 당근마켓 스타일 컬러
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);

  LatLng? _selectedPosition;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '지도에서 위치 선택',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // 위치가 선택되었을 때만 '완료' 버튼 표시
          if (_selectedPosition != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(_selectedPosition);
                },
                icon: const Icon(
                  Icons.check_circle,
                  color: carrotOrange,
                  size: 20,
                ),
                label: const Text(
                  '완료',
                  style: TextStyle(
                    color: carrotOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: carrotLightOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            // 지도를 탭했을 때 호출되는 콜백
            onTap: (LatLng position) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedPosition = position;
                _markers.clear();
                _markers.add(
                  Marker(
                    markerId: const MarkerId('selected-location'),
                    position: position,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                  ),
                );
              });
            },
            markers: _markers,
          ),
          // 안내 메시지
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _selectedPosition == null ? Colors.white : carrotLightOrange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedPosition == null 
                  ? Colors.grey[100] 
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _selectedPosition == null 
                  ? Icons.touch_app_rounded 
                  : Icons.location_on_rounded,
              color: _selectedPosition == null 
                  ? Colors.grey[600] 
                  : carrotOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedPosition == null
                  ? '지도를 탭하여 위치를 선택하세요'
                  : '위치가 선택되었습니다. 완료 버튼을 눌러주세요',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _selectedPosition == null 
                    ? Colors.grey[700] 
                    : carrotOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}