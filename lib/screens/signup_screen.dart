// lib/screens/signup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

// 회원가입 화면을 담당하는 SignupScreen 클래스입니다.
// 사용자가 이름, 이메일, 비밀번호, 프로필 사진을 입력하고 회원가입을 요청합니다.
// 화면 상태(입력 필드 값, 선택된 이미지 등)를 관리하기 위해 StatefulWidget으로 작성되었습니다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

// SignupScreen의 상태를 관리하는 State 클래스입니다.
class _SignupScreenState extends State<SignupScreen> {
  // 사용자의 입력값을 관리하는 컨트롤러들입니다.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // 사용자가 선택한 프로필 이미지를 저장하는 변수입니다.
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // 화면이 사라질 때 컨트롤러들을 메모리에서 해제하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 갤러리에서 프로필 이미지를 선택하는 비동기 함수입니다.
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // 이미지가 선택되면 화면을 다시 그려 이미지를 표시합니다.
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  // 회원가입 버튼을 눌렀을 때 실행되는 비동기 함수입니다.
  Future<void> _signup() async {
    // AuthService를 통해 백엔드에 회원가입 요청을 보냅니다.
    final success = await _authService.signup(
      _usernameController.text,
      _emailController.text,
      _passwordController.text,
      _profileImage,
    );

    // 회원가입 성공 시
    if (success) {
      if (!mounted) return;
      // 이전 화면(로그인 화면)으로 돌아갑니다.
      Navigator.pop(context);
    }
    // 회원가입 실패 시
    else {
      if (!mounted) return;
      // 사용자에게 실패 메시지를 알리는 SnackBar를 띄웁니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("회원가입 실패: 정보를 다시 확인해주세요."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold는 앱의 기본 구조를 제공하는 위젯입니다.
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      // SingleChildScrollView를 사용해 키보드가 올라와도 화면이 스크롤되게 합니다.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로축을 화면 전체에 펼침
            children: [
              const SizedBox(height: 50.0),
              // 프로필 이미지를 선택하는 원형 아바타 위젯입니다.
              _buildProfileImagePicker(),
              const SizedBox(height: 24.0),
              // 사용자 이름 입력 필드
              _buildTextField(
                controller: _usernameController,
                labelText: '사용자 이름',
                icon: Icons.person,
              ),
              const SizedBox(height: 16.0),
              // 이메일 입력 필드
              _buildTextField(
                controller: _emailController,
                labelText: '이메일',
                icon: Icons.email,
              ),
              const SizedBox(height: 16.0),
              // 비밀번호 입력 필드
              _buildTextField(
                controller: _passwordController,
                labelText: '비밀번호',
                icon: Icons.lock,
                isObscure: true, // 비밀번호를 *로 표시
              ),
              const SizedBox(height: 24.0),
              // 회원가입 버튼
              _buildSignupButton(),
            ],
          ),
        ),
      ),
    );
  }

  // 텍스트 입력 필드를 만드는 커스텀 위젯입니다.
  // 로그인 화면과 동일한 디자인을 적용했습니다.
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  // 프로필 이미지 선택 위젯입니다.
  // 원형 아바타를 누르면 갤러리가 열립니다.
  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[200],
        backgroundImage:
            _profileImage != null ? FileImage(_profileImage!) : null,
        child:
            _profileImage == null
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
      ),
    );
  }

  // 회원가입 버튼을 만드는 커스텀 위젯입니다.
  // 로그인 화면의 로그인 버튼과 동일한 디자인을 적용했습니다.
  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: _signup,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      child: const Text(
        '회원가입',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    );
  }
}
