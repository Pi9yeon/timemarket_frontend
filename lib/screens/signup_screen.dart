// lib/screens/signup_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  // 사용자의 입력값을 관리하는 컨트롤러들입니다.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // 사용자가 선택한 프로필 이미지를 저장하는 변수입니다.
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  
  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // 당근마켓 스타일의 컬러 테마
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);
  static const Color carrotDarkOrange = Color(0xFFE65100);
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
  }

  // 화면이 사라질 때 컨트롤러들을 메모리에서 해제하여 메모리 누수를 방지합니다.
  @override
  void dispose() {
    _animationController.dispose();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20.0),
                    // 프로필 이미지 섹션
                    _buildProfileImagePicker(),
                    const SizedBox(height: 40.0),
                    // 회원가입 폼 카드
                    _buildSignupCard(),
                    const SizedBox(height: 40.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSignupCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '정보 입력',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          // 사용자 이름 입력 필드
          _buildTextField(
            controller: _usernameController,
            labelText: '사용자 이름',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16.0),
          // 이메일 입력 필드
          _buildTextField(
            controller: _emailController,
            labelText: '이메일',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 16.0),
          // 비밀번호 입력 필드
          _buildTextField(
            controller: _passwordController,
            labelText: '비밀번호',
            icon: Icons.lock_outline,
            isObscure: true,
          ),
          const SizedBox(height: 28.0),
          // 회원가입 버튼
          _buildSignupButton(),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: carrotOrange,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: const BorderSide(color: carrotOrange, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // 프로필 이미지 선택 위젯입니다.
  // 원형 아바타를 누르면 갤러리가 열립니다.
  Widget _buildProfileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _pickImage();
        },
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
                border: Border.all(
                  color: carrotLightOrange,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: carrotOrange.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: _profileImage != null
                    ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImage == null
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey[400],
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [carrotOrange, carrotDarkOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 회원가입 버튼을 만드는 커스텀 위젯입니다.
  // 로그인 화면의 로그인 버튼과 동일한 디자인을 적용했습니다.
  Widget _buildSignupButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [carrotOrange, carrotDarkOrange],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: carrotOrange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _signup();
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          elevation: 0,
        ),
        child: const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
