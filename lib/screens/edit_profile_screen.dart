// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'login_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen(this.user, {super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();

  // 기존 정보 표시를 위한 컨트롤러
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  // 비밀번호 변경을 위한 컨트롤러
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 프로필 정보 및 비밀번호 변경을 함께 처리하는 함수
  Future<void> _updateProfile() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // 비밀번호 변경 필드가 모두 채워져 있을 때만 비밀번호 변경 로직 실행
    if (_currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("새 비밀번호가 일치하지 않습니다.")));
        setState(() => _isLoading = false);
        return;
      }

      // ✅ 비밀번호 변경 API 호출 및 오류 수정
      bool passwordChangeSuccess = await _userService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (passwordChangeSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호가 성공적으로 변경되었습니다. 다시 로그인해주세요.")),
        );

        // ✅ 비밀번호 변경 성공 시 로그아웃 및 로그인 화면으로 이동
        await _userService.authService.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
        return; // 비밀번호 변경 후에는 즉시 종료
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.")),
        );
        setState(() => _isLoading = false);
        return;
      }
    } else {
      // 비밀번호 변경 필드가 비어있으면 닉네임, 이메일 업데이트 로직 실행
      // TODO: 백엔드에 닉네임/이메일 변경 API가 준비되면 이 로직을 구현
      bool updateSuccess = await _userService.updateMyInfo(
        _usernameController.text,
        _emailController.text,
      );
      if (updateSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("프로필이 성공적으로 업데이트되었습니다.")));
        Navigator.pop(context, true); // 성공적으로 업데이트되면 이전 화면으로 돌아감
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("프로필 업데이트에 실패했습니다.")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '기본 정보 (수정 불가)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildTextField(
              controller: _usernameController,
              labelText: '사용자 이름',
              icon: Icons.person,
              isReadOnly: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              labelText: '이메일',
              icon: Icons.email,
              isReadOnly: true,
            ),
            const SizedBox(height: 32),

            const Text(
              '비밀번호 변경',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _buildTextField(
              controller: _currentPasswordController,
              labelText: '현재 비밀번호',
              icon: Icons.lock_outline,
              isObscure: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _newPasswordController,
              labelText: '새 비밀번호',
              icon: Icons.lock,
              isObscure: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _confirmPasswordController,
              labelText: '새 비밀번호 확인',
              icon: Icons.lock,
              isObscure: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _updateProfile,
                  child: const Text('수정하기'),
                ),
          ],
        ),
      ),
    );
  }

  // 재사용 가능한 텍스트 필드 헬퍼 위젯
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isObscure = false,
    bool isReadOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.grey[400]! : Colors.grey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.grey[400]! : Colors.blueAccent,
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
      ),
    );
  }
}
