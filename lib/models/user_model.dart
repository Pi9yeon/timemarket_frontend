// lib/models/user_model.dart

// User 모델은 백엔드에서 받아온 사용자 정보를 담는 Dart 클래스입니다.
// 이 모델의 필드는 백엔드 API 응답과 일치해야 합니다.
class User {
  final int id;
  final String username;
  final String? email; // nullable로 변경 (리뷰 API에서 null일 수 있음)
  final String? profileImageUrl; // ✅ 프로필 이미지 URL 필드 (null 가능)
  
  // nickname getter 추가 (username과 동일)
  String get nickname => username;

  // ✅ 프로필 화면에 필요한 추가 필드들
  final double timeCredit; // 사용자가 보유한 시간 크레딧 (Time Credit)
  final double cumulativeTime; // 누적 활동 시간
  final double rating; // 평점 (기존 필드, 하위 호환성 유지)
  final String? skillsAndRequests; // 사용자의 재능/요청 (자기소개)
  
  // ✅ 리뷰 시스템 관련 필드 추가
  final double? averageRating; // 평균 평점 (0.00~5.00, 리뷰 기반 계산)
  final int? ratingCount; // 받은 리뷰 개수

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
    // ✅ 리뷰 시스템 필드 (nullable, 백엔드에서 제공하지 않으면 null)
    this.averageRating,
    this.ratingCount,
  });

  // 백엔드 API 응답(JSON)을 User 모델 객체로 변환하는 팩토리 생성자입니다.
  // 이 함수는 백엔드에서 받은 JSON 데이터를 Dart 객체로 변환하는 역할을 합니다.
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // 디버깅: User 모델 파싱 시 프로필 이미지 확인
      final profileImage = json['profile_image'];
      final nickname = json['nickname'];
      final email = json['email'];
      
      print('👤 [User.fromJson] 사용자 "$nickname" (ID: ${json['id']}) 파싱:');
      print('   - email: $email (${email.runtimeType})');
      print('   - profile_image: $profileImage (${profileImage.runtimeType})');
      
      return User(
        id: json['id'] as int,
        username: nickname as String, // 백엔드 필드명 'nickname'을 'username'으로 매핑
        email: email as String?, // nullable로 처리
        profileImageUrl: profileImage as String?, // 백엔드 필드명과 동일
        // ✅ JSON 응답에서 추가된 필드들을 파싱하여 할당합니다.
        // 값이 null일 경우 오류를 막기 위해 기본값(0.0)을 설정합니다.
        timeCredit: _parseDouble(json['time_credit']),
        cumulativeTime: _parseDouble(json['cumulative_time']),
        rating: _parseDouble(json['rating']),
        skillsAndRequests: json['skills_and_requests'] as String?,
        // ✅ 리뷰 시스템 필드 파싱
        // averageRating이 없으면 rating 값으로 폴백 (하위 호환성)
        averageRating: json['average_rating'] != null 
            ? _parseDouble(json['average_rating'])
            : (json['rating'] != null ? _parseDouble(json['rating']) : null),
        ratingCount: json['rating_count'] as int?,
      );
    } catch (e, stackTrace) {
      print('❌ [User.fromJson] 파싱 실패: $e');
      print('   - Stack trace: $stackTrace');
      print('   - JSON: $json');
      rethrow;
    }
  }
  
  /// double 값을 안전하게 파싱하는 헬퍼 메서드
  /// 
  /// 백엔드에서 숫자 필드가 다양한 형태로 올 수 있음:
  /// - int: 5
  /// - double: 5.0
  /// - String: "5.0"
  /// - null
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    
    // 최후의 수단: toString() 후 파싱
    return double.parse(value.toString());
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
      if (averageRating != null) 'average_rating': averageRating,
      if (ratingCount != null) 'rating_count': ratingCount,
    };
  }
  
  /// 표시용 평점 가져오기 (averageRating 우선, 없으면 rating)
  double get displayRating => averageRating ?? rating;
  
  /// 평점 텍스트 (별 + 숫자)
  String get ratingText {
    final rating = displayRating;
    final count = ratingCount ?? 0;
    return '⭐ ${rating.toStringAsFixed(1)} ($count개 리뷰)';
  }
}
