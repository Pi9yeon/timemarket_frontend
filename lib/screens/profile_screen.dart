// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timemarket_frontend/screens/time_post_list_screen.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final _picker = ImagePicker();
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  // 내 정보를 서버에서 가져오는 함수
  Future<void> _fetchUserInfo() async {
    final user = await _userService.getMyInfo();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  // 갤러리에서 이미지를 선택하고 업로드하는 함수
  Future<void> _pickImageAndUpload() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File newImage = File(pickedFile.path);
      // TODO: user_service에 프로필 이미지 업로드 API 호출 로직 구현 필요
      // bool success = await _userService.updateProfileImage(newImage);
      // if (success) {
      //   _fetchUserInfo(); // 성공 시 유저 정보 다시 로드
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 유저 정보가 로딩 중일 때 로딩 화면 표시
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이 페이지')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user!;
    return Scaffold(
      // 마이페이지 전용 상단 바
      appBar: AppBar(
        title: const Text('마이 페이지'),
        // 지도 화면과 동일한 버튼들을 배치하여 일관성 유지
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
              // 이미 마이페이지이므로 아무 동작 안함
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
      // 마이페이지 본문
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 프로필 이미지 섹션
              Stack(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                    child:
                        user.profileImageUrl == null
                            ? Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey[600],
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _pickImageAndUpload,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 사용자 이름 및 이메일
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // 정보 수정 버튼
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(user),
                    ),
                  );
                  // 수정 화면에서 돌아왔을 때 정보 갱신
                  if (result == true) {
                    _fetchUserInfo();
                  }
                },
                child: const Text('정보 수정'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              // 정보 카드 목록
              _buildInfoCard(
                title: "시간 지갑 잔고",
                value: "${user.timeCredit.toStringAsFixed(1)} 시간",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WalletScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: "누적 거래 시간",
                value: "${user.cumulativeTime.toStringAsFixed(1)} 시간",
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: "평점",
                value: "${user.rating.toStringAsFixed(1)} / 5.0",
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 정보를 보여주는 카드 위젯
  Widget _buildInfoCard({
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
