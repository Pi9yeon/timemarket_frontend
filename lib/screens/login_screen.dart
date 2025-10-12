import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

// LoginScreen 클래스는 사용자가 로그인 정보를 입력하고,
// 로그인 처리를 담당하는 화면입니다.
// StatefulWidget으로 만들어져서 화면 상태(텍스트 입력값 등)를 관리할 수 있습니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// _LoginScreenState 클래스는 LoginScreen의 실제 상태를 관리합니다.
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  // 사용자의 입력값을 저장하고 관리하는 컨트롤러들입니다.
  // TextField에 연결되어 사용자가 입력한 텍스트를 가져올 수 있습니다.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 인증(로그인, 회원가입)과 관련된 API 통신을 담당하는 서비스 클래스입니다.
  // 백엔드와의 통신을 처리합니다.
  final AuthService _authService = AuthService();
  
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
      duration: const Duration(milliseconds: 1000),
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

  // 화면이 사라질 때 사용했던 컨트롤러들을 메모리에서 해제하여
  // 불필요한 자원 낭비를 막는 중요한 역할을 합니다.
  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 버튼을 눌렀을 때 실행되는 비동기 함수입니다.
  // 백엔드에 로그인 요청을 보내고 결과를 처리합니다.
  Future<void> _login() async {
    // _authService의 login 함수를 호출하여 백엔드로 로그인 정보를 보냅니다.
    // 결과에 따라 success 변수에 true 또는 false가 저장됩니다.
    final success = await _authService.login(
      _usernameController.text,
      _emailController.text,
      _passwordController.text,
    );

    // 로그인 성공 시
    if (success) {
      // 위젯이 아직 화면에 존재하는지 확인하여 오류를 방지합니다.
      if (!mounted) return;

      // 로그인 성공 후 MainScreen 화면으로 이동하고, 이전 화면(로그인 화면)을 제거합니다.
      // 이렇게 하면 사용자가 뒤로 가기 버튼을 눌러도 로그인 화면으로 돌아가지 않습니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
    // 로그인 실패 시
    else {
      if (!mounted) return;

      // 사용자에게 로그인 실패 메시지를 표시하는 알림(SnackBar)을 띄웁니다.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("로그인 실패: 아이디, 이메일, 비밀번호를 확인해주세요."),
          backgroundColor: Colors.red, // 실패 알림은 빨간색으로 표시하여 눈에 띄게 합니다.
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
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
                      const SizedBox(height: 60.0),
                      // 로고 섹션
                      _buildLogoSection(),
                      const SizedBox(height: 60.0),
                      // 로그인 폼 카드
                      _buildLoginCard(),
                      const SizedBox(height: 24.0),
                      // 회원가입 버튼
                      _buildSignupSection(),
                      const SizedBox(height: 40.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoSection() {
    return Column(
      children: [
        // 로고 컨테이너
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [carrotOrange, carrotDarkOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: carrotOrange.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 50,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        // 앱 이름
        const Text(
          'TimeMarket',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        // 슬로건
        Text(
          '시간을 나누고 가치를 교환하는 곳',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLoginCard() {
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
            '로그인',
            style: TextStyle(
              fontSize: 24,
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
          // 로그인 버튼
          _buildLoginButton(),
        ],
      ),
    );
  }
  
  Widget _buildSignupSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '계정이 없으신가요?',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: carrotOrange,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: const Text(
            '회원가입',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // 텍스트 입력 필드를 만드는 커스텀 위젯입니다.
  // 이 위젯을 사용하면 여러 개의 입력 필드를 일관된 디자인으로 쉽게 만들 수 있습니다.
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

  // 로그인 버튼을 만드는 커스텀 위젯입니다.
  Widget _buildLoginButton() {
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
          _login();
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
          '로그인',
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
