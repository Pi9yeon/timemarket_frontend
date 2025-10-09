// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'chat_list_screen.dart'; // ✅ 새로 만든 대화 목록 화면 import
import 'trade_history_screen.dart'; // ✅ 거래내역 화면 import

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _picker = ImagePicker();
  User? _user;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = await _userService.getMyInfo();
    setState(() {
      _user = user;
    });
  }

  Future<void> _pickImageAndUpload() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File newImage = File(pickedFile.path);
      bool success = await _userService.updateProfileImage(newImage);
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("프로필 이미지가 성공적으로 변경되었습니다.")),
        );
        _fetchUserInfo();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("이미지 변경에 실패했습니다.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(user),
                ),
              );
              if (result == true) {
                _fetchUserInfo();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            Text(
              user.username,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "재능/요청",
              value: user.skillsAndRequests ?? '미입력',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "시간 크레딧 잔고",
              value: "${user.timeCredit.toStringAsFixed(1)} Time",
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "누적 거래 시간",
              value: "${user.cumulativeTime.toStringAsFixed(1)} Time",
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "평점",
              value: "${user.rating.toStringAsFixed(1)} / 5.0",
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // ✅ '대화 목록 보기' 메뉴 추가
            _buildInfoCard(
              title: "대화 목록",
              value: "확인하기",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "거래 내역",
              value: "자세히 보기",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TradeHistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              title: "내가 쓴 리뷰",
              value: "자세히 보기",
              onTap: () {
                // TODO: 내가 쓴 리뷰 페이지로 이동
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await _userService.authService.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }

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
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
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
