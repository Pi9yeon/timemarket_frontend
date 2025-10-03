import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'login_screen.dart'; // LoginScreen 경로 맞게 import 꼭 해주세요
import '../screens/time_post_map_screen.dart';
import 'time_post_list_screen.dart'; // 새로 만든 화면 import

// LoginScreen 클래스는 사용자가 로그인 정보를 입력하고,
// 로그인 처리를 담당하는 화면입니다.
// StatefulWidget으로 만들어져서 화면 상태(텍스트 입력값 등)를 관리할 수 있습니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// _LoginScreenState 클래스는 LoginScreen의 실제 상태를 관리합니다.
class _LoginScreenState extends State<LoginScreen> {
  // 사용자의 입력값을 저장하고 관리하는 컨트롤러들입니다.
  // TextField에 연결되어 사용자가 입력한 텍스트를 가져올 수 있습니다.
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 인증(로그인, 회원가입)과 관련된 API 통신을 담당하는 서비스 클래스입니다.
  // 백엔드와의 통신을 처리합니다.
  final AuthService _authService = AuthService();

  // 화면이 사라질 때 사용했던 컨트롤러들을 메모리에서 해제하여
  // 불필요한 자원 낭비를 막는 중요한 역할을 합니다.
  @override
  void dispose() {
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

      // 로그인 성공 후 TimePostMapScreen 화면으로 이동하고, 이전 화면(로그인 화면)을 제거합니다.
      // 이렇게 하면 사용자가 뒤로 가기 버튼을 눌러도 로그인 화면으로 돌아가지 않습니다.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TimePostMapScreen()),
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
    // Scaffold는 앱의 기본 구조(앱 바, 본문 등)를 제공하는 위젯입니다.
    return Scaffold(
      // body에 SingleChildScrollView를 사용하면 화면 내용이 길어져도 스크롤이 가능해집니다.
      // 키보드가 올라와도 화면 요소가 가려지지 않게 하는 중요한 역할을 합니다.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // 자식 위젯들을 세로 방향으로 배치하는 위젯입니다.
            mainAxisAlignment: MainAxisAlignment.center, // 세로축 중앙 정렬
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로축을 화면 전체에 펼칩니다.
            children: [
              const SizedBox(height: 80.0), // 상단에 여백을 줍니다.
              // 프로젝트 로고나 이름 텍스트를 표시합니다.
              //
              const Text(
                'TimeMarket',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10.0),
              // 프로젝트 슬로건을 표시합니다.
              const Text(
                '시간을 나누고 가치를 교환하는 곳',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50.0),
              // 사용자 이름 입력 필드
              _buildTextField(
                controller: _usernameController,
                labelText: '사용자 이름',
                icon: Icons.person,
              ),
              const SizedBox(height: 16.0), // 입력 필드 간의 여백
              // 이메일 입력 필드
              _buildTextField(
                controller: _emailController,
                labelText: '이메일',
                icon: Icons.email,
              ),
              const SizedBox(height: 16.0), // 입력 필드 간의 여백
              // 비밀번호 입력 필드
              _buildTextField(
                controller: _passwordController,
                labelText: '비밀번호',
                icon: Icons.lock,
                isObscure: true, // 비밀번호 숨김 처리를 합니다.
              ),
              const SizedBox(height: 24.0), // 버튼 위에 여백을 줍니다.
              // 로그인 버튼
              _buildLoginButton(),
              const SizedBox(height: 16.0), // 버튼 간의 여백
              // 회원가입 버튼
              _buildSignupButton(context),
            ],
          ),
        ),
      ),
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
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: labelText, // 입력 필드 위에 표시되는 힌트 텍스트
        prefixIcon: Icon(icon, color: Colors.blueAccent), // 텍스트 앞에 표시되는 아이콘
        border: OutlineInputBorder(
          // 테두리 디자인 설정
          borderRadius: BorderRadius.circular(12.0), // 모서리를 둥글게 만듭니다.
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        enabledBorder: OutlineInputBorder(
          // 입력 필드가 활성화되지 않았을 때의 테두리
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          // 입력 필드에 커서가 있을 때의 테두리
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        filled: true, // 배경색을 채울지 여부
        fillColor: Colors.grey[50], // 배경색
      ),
    );
  }

  // 로그인 버튼을 만드는 커스텀 위젯입니다.
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login, // 버튼 클릭 시 _login 함수 실행
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // 버튼 텍스트 색상
        backgroundColor: Colors.blueAccent, // 버튼 배경색
        shape: RoundedRectangleBorder(
          // 버튼 모양 설정
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0), // 버튼 내부 여백
      ),
      child: const Text(
        '로그인',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 회원가입 버튼을 만드는 커스텀 위젯입니다.
  Widget _buildSignupButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        // 회원가입 버튼 클릭 시 SignupScreen 화면으로 이동합니다.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      },
      style: TextButton.styleFrom(
        foregroundColor: Colors.blueAccent, // 버튼 텍스트 색상
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
      ),
      child: const Text('회원가입', style: TextStyle(fontSize: 16.0)),
    );
  }
}
