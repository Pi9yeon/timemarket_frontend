// lib/screens/profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';

// ✅ 프로필 이미지 변경 기능을 위해 StatefulWidget으로 변경
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final _picker = ImagePicker();
  User? _user;

  Future<void> _fetchUserInfo() async {
    final user = await _userService.getMyInfo();
    setState(() {
      _user = user;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  // ✅ 갤러리에서 이미지를 선택하고 업로드하는 함수
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
      appBar: AppBar(title: const Text('내 프로필')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ 이미지와 버튼 레이아웃 재현
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        user.profileImageUrl != null
                            ? NetworkImage(user.profileImageUrl!)
                            : null,
                    child:
                        user.profileImageUrl == null
                            ? Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: _pickImageAndUpload, // ✅ 이미지 변경 함수 호출
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user.username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '⭐ 평점: ${user.rating.toStringAsFixed(1)} (24)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
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
                child: const Text('프로필 수정'),
              ),
            ),
            const SizedBox(height: 32),

            // ✅ 핵심 정보 요약 섹션 디자인 재현
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.watch_later_outlined,
                      label: '보유 시간',
                      value: '${user.timeCredit.toStringAsFixed(1)}h',
                    ),
                    _buildSummaryItem(
                      icon: Icons.thumb_up_alt_outlined,
                      label: '누적 봉사 시간',
                      value: '${user.cumulativeTime.toStringAsFixed(1)}h',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ✅ 계정 및 추가 기능 섹션 디자인 재현
            const Text(
              '계정 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildListTile(
              title: '아이디 (닉네임)',
              trailing: Text(
                user.username,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const Divider(), // ✅ 구분선 추가
            _buildListTile(
              title: '이메일',
              trailing: Text(
                user.email,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const Divider(), // ✅ 구분선 추가
            const SizedBox(height: 24),
            const Text(
              '추가 기능',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildListTile(
              title: '거래 내역 보기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
              },
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
              ), // ✅ 아이콘 추가
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ), // ✅ 아이콘 추가
            ),
            const Divider(), // ✅ 구분선 추가
            _buildListTile(
              title: '내가 쓴 리뷰 보기',
              onTap: () {
                // TODO: 내가 쓴 리뷰 페이지로 이동
              },
              leading: const Icon(Icons.reviews_outlined), // ✅ 아이콘 추가
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ), // ✅ 아이콘 추가
            ),
            const Divider(), // ✅ 구분선 추가
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Icon? leading,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      leading: leading, // ✅ leading 아이콘 추가
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
