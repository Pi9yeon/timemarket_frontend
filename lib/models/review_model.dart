// lib/models/review_model.dart

import 'user_model.dart';

/// 리뷰 모델
/// 백엔드 API 응답 구조:
/// - author: 리뷰 작성자 (User 객체)
/// - target: 리뷰 대상자 (User 객체)
/// - trade: 거래 ID (int) - 백엔드는 'trade' 필드명 사용
/// - rating: 별점 (0.5~5.0, 0.5 단위)
/// - content: 리뷰 내용 (optional)
/// - created_at: 작성일시
class Review {
  final int id;
  final User author; // 리뷰 작성자
  final User target; // 리뷰 대상자
  final int tradeRequest; // 거래 ID (백엔드는 'trade'로 전송)
  final double rating; // 별점 (0.5~5.0)
  final String? content; // 리뷰 내용 (optional)
  final DateTime createdAt;

  Review({
    required this.id,
    required this.author,
    required this.target,
    required this.tradeRequest,
    required this.rating,
    this.content,
    required this.createdAt,
  });

  /// 백엔드 JSON 응답을 Review 객체로 변환
  /// 
  /// 주의사항:
  /// 1. 백엔드는 거래 ID를 'trade' 필드명으로 전송
  /// 2. author와 target은 중첩된 User 객체로 전송됨
  /// 3. content는 null일 수 있음 (optional)
  /// 4. User 객체의 email이 null일 수 있음
  factory Review.fromJson(Map<String, dynamic> json) {
    print('📝 [Review.fromJson] 리뷰 파싱 시작');
    print('   - Raw JSON keys: ${json.keys.toList()}');
    
    try {
      // author 필드 검증
      if (json['author'] == null) {
        throw Exception('❌ Review.fromJson: author 필드가 null입니다');
      }
      
      // target 필드 검증
      if (json['target'] == null) {
        throw Exception('❌ Review.fromJson: target 필드가 null입니다');
      }
      
      // 거래 ID 필드 처리 (백엔드는 'trade' 사용, 없으면 'trade_request' 체크)
      final tradeId = json['trade'] ?? json['trade_request'];
      if (tradeId == null) {
        throw Exception('❌ Review.fromJson: trade/trade_request 필드가 null입니다');
      }
      
      print('   - author: ${json['author']}');
      print('   - target: ${json['target']}');
      print('   - tradeId: $tradeId');
      
      final review = Review(
        id: json['id'],
        author: User.fromJson(json['author'] as Map<String, dynamic>),
        target: User.fromJson(json['target'] as Map<String, dynamic>),
        tradeRequest: tradeId is int ? tradeId : int.parse(tradeId.toString()),
        rating: _parseRating(json['rating']),
        content: json['content'] as String?, // 명시적 캐스팅
        createdAt: DateTime.parse(json['created_at'] as String),
      );
      
      print('✅ [Review.fromJson] 파싱 성공');
      print('   - ID: ${review.id}');
      print('   - 작성자: ${review.author.username} (ID: ${review.author.id})');
      print('   - 대상자: ${review.target.username} (ID: ${review.target.id})');
      print('   - 별점: ${review.rating}');
      
      return review;
    } catch (e, stackTrace) {
      print('❌ [Review.fromJson] 파싱 실패: $e');
      print('   - Stack trace: $stackTrace');
      print('   - JSON: $json');
      rethrow;
    }
  }
  
  /// rating 필드를 안전하게 double로 변환하는 헬퍼 메서드
  /// 
  /// 백엔드에서 rating이 다양한 형태로 올 수 있음:
  /// - int: 5
  /// - double: 5.0
  /// - String: "5.0"
  /// - null
  static double _parseRating(dynamic value) {
    if (value == null) return 0.0;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    
    // 최후의 수단: toString() 후 파싱
    return double.parse(value.toString());
  }

  /// Review 객체를 JSON으로 변환 (리뷰 작성 시 사용)
  /// 
  /// 백엔드 POST 요청 형식:
  /// {
  ///   "trade": int,
  ///   "rating": double,
  ///   "content": string (optional)
  /// }
  /// 
  /// 주의: author, target은 백엔드에서 자동 설정되므로 전송하지 않음
  Map<String, dynamic> toJson() {
    return {
      'trade': tradeRequest, // 백엔드는 'trade' 필드명 사용
      'rating': rating,
      if (content != null && content!.isNotEmpty) 'content': content,
    };
  }

  /// 별점을 별 아이콘 문자열로 변환 (UI 표시용)
  String get ratingStars {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    
    String stars = '⭐' * fullStars;
    if (hasHalfStar) stars += '✨';
    
    return '$stars (${rating.toStringAsFixed(1)})';
  }
}
