// lib/models/user_model.dart

// User 모델은 백엔드에서 받아온 사용자 정보를 담는 Dart 클래스입니다.
// 이 모델의 필드는 백엔드 API 응답과 일치해야 합니다.
class User {
  final int id;
  final String username;
  final String email;
  final String? profileImageUrl; // ✅ 프로필 이미지 URL 필드 (null 가능)
  
  // nickname getter 추가 (username과 동일)
  String get nickname => username;

  // ✅ 프로필 화면에 필요한 추가 필드들
  final double timeCredit; // 사용자가 보유한 시간 크레딧 (Time Credit)
  final double cumulativeTime; // 누적 활동 시간
  final double rating; // 평점
  final String? skillsAndRequests; // 사용자의 재능/요청 (자기소개)

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    // ✅ 추가된 필드들에 대한 기본값 설정
    this.timeCredit = 0.0,
    this.cumulativeTime = 0.0,
    this.rating = 0.0,
    this.skillsAndRequests,
  });

  // 백엔드 API 응답(JSON)을 User 모델 객체로 변환하는 팩토리 생성자입니다.
  // 이 함수는 백엔드에서 받은 JSON 데이터를 Dart 객체로 변환하는 역할을 합니다.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['nickname'], // 백엔드 필드명 'nickname'을 'username'으로 매핑
      email: json['email'],
      profileImageUrl: json['profile_image'], // 백엔드 필드명과 동일
      // ✅ JSON 응답에서 추가된 필드들을 파싱하여 할당합니다.
      // 값이 null일 경우 오류를 막기 위해 기본값(0.0)을 설정합니다.
      timeCredit: (json['time_credit'] ?? 0.0).toDouble(),
      cumulativeTime: (json['cumulative_time'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      skillsAndRequests: json['skills_and_requests'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': username, // 백엔드 필드명에 맞춰 'nickname'으로 변환
      'email': email,
      'profile_image': profileImageUrl,
      'time_credit': timeCredit,
      'cumulative_time': cumulativeTime,
      'rating': rating,
      'skills_and_requests': skillsAndRequests,
    };
  }
}
