import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/time_post_list_screen.dart';
import 'screens/time_post_map_screen.dart';
import 'services/auth_service.dart';
// import 'package:flutter_localizations/flutter_localizations.dart'; // 📌 추가

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Market',
      theme: ThemeData(primarySwatch: Colors.blue),
      // // 📌 아래 두 속성을 추가합니다.
      // localizationsDelegates: [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', ''), // 영어
      //   Locale('ko', ''), // 한국어
      // ],
      home: FutureBuilder<String?>(
        future: _authService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != null) {
            return LoginScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
