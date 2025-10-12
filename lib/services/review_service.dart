// lib/services/review_service.dart

import 'package:dio/dio.dart';
import '../models/review_model.dart';
import 'api_client.dart';

/// 리뷰 API 서비스
/// 
/// 백엔드 API 엔드포인트:
/// - POST /api/reviews/create/ - 리뷰 작성 (인증 필요)
/// - GET /api/reviews/ - 전체 리뷰 목록
/// - GET /api/reviews/user/<user_id>/ - 특정 유저가 받은 리뷰
/// - GET /api/reviews/<id>/ - 특정 리뷰 조회
/// - DELETE /api/reviews/<id>/ - 리뷰 삭제 (작성자/관리자만)
class ReviewService {
  final ApiClient _apiClient = ApiClient();
  
  Dio get _dio => _apiClient.dio;

  /// 리뷰 작성
  /// 
  /// 파라미터:
  /// - tradeId: 거래 ID (완료된 거래만 가능)
  /// - rating: 별점 (0.5~5.0, 0.5 단위)
  /// - content: 리뷰 내용 (optional)
  /// 
  /// 검증 사항:
  /// - 완료된 거래(status='completed')만 리뷰 가능
  /// - 거래 참여자(requester 또는 receiver)만 작성 가능
  /// - 같은 거래에 중복 리뷰 작성 불가
  /// - 별점은 0.5 단위로만 입력 가능
  /// - 리뷰 대상자는 자동으로 거래 상대방으로 설정됨
  /// 
  /// 반환: 성공 여부 (bool)
  /// 
  /// 주의: 백엔드는 201 응답만 반환하고 생성된 Review 객체를 반환하지 않음
  Future<bool> createReview({
    required int tradeId,
    required double rating,
    String? content,
  }) async {
    try {
      print('📝 [ReviewService] 리뷰 작성 요청');
      print('   - tradeId: $tradeId');
      print('   - rating: $rating');
      print('   - content: ${content ?? "(없음)"}');
      
      // 별점 검증 (0.5 단위)
      if (rating < 0.5 || rating > 5.0) {
        print('❌ [ReviewService] 별점 범위 오류: $rating (0.5~5.0 범위 필요)');
        return false;
      }
      
      if ((rating * 2) % 1 != 0) {
        print('❌ [ReviewService] 별점 단위 오류: $rating (0.5 단위만 가능)');
        return false;
      }
      
      final response = await _dio.post(
        '/reviews/create/',
        data: {
          'trade': tradeId, // 백엔드는 'trade' 필드명 사용
          'rating': rating,
          if (content != null && content.isNotEmpty) 'content': content,
        },
      );

      print('📝 [ReviewService] 응답 상태: ${response.statusCode}');
      print('   - 응답 데이터: ${response.data}');
      
      if (response.statusCode == 201) {
        print('✅ [ReviewService] 리뷰 작성 성공');
        return true;
      }
      
      print('❌ [ReviewService] 예상치 못한 응답 코드: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('❌ [ReviewService] 리뷰 작성 실패 (DioException)');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 에러 메시지: ${e.response?.data}');
      print('   - 예외: $e');
      return false;
    } catch (e) {
      print('❌ [ReviewService] 리뷰 작성 실패 (예외): $e');
      return false;
    }
  }

  /// 전체 리뷰 목록 조회
  Future<List<Review>> getAllReviews() async {
    try {
      print('📝 [ReviewService] 전체 리뷰 목록 조회');
      
      final response = await _dio.get('/reviews/');

      print('📝 [ReviewService] 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('✅ [ReviewService] 리뷰 ${data.length}개 조회 성공');
        
        return data.map((json) => Review.fromJson(json)).toList();
      }
      
      print('❌ [ReviewService] 예상치 못한 응답 코드: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      print('❌ [ReviewService] 리뷰 목록 조회 실패 (DioException)');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 에러 메시지: ${e.response?.data}');
      return [];
    } catch (e) {
      print('❌ [ReviewService] 리뷰 목록 조회 실패: $e');
      return [];
    }
  }

  /// 특정 유저가 받은 리뷰 목록 조회
  /// 
  /// 파라미터:
  /// - userId: 대상 유저 ID
  /// 
  /// 반환: Review 리스트 (target.id == userId인 리뷰들)
  Future<List<Review>> getReviewsForUser(int userId) async {
    try {
      print('📝 [ReviewService] 유저 $userId의 리뷰 조회');
      
      final response = await _dio.get('/reviews/user/$userId/');

      print('📝 [ReviewService] 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('✅ [ReviewService] 유저 $userId의 리뷰 ${data.length}개 조회 성공');
        
        return data.map((json) => Review.fromJson(json)).toList();
      }
      
      print('❌ [ReviewService] 예상치 못한 응답 코드: ${response.statusCode}');
      return [];
    } on DioException catch (e) {
      print('❌ [ReviewService] 유저 리뷰 조회 실패 (DioException)');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 에러 메시지: ${e.response?.data}');
      return [];
    } catch (e) {
      print('❌ [ReviewService] 유저 리뷰 조회 실패: $e');
      return [];
    }
  }

  /// 특정 리뷰 상세 조회
  Future<Review?> getReview(int reviewId) async {
    try {
      print('📝 [ReviewService] 리뷰 $reviewId 조회');
      
      final response = await _dio.get('/reviews/$reviewId/');

      print('📝 [ReviewService] 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ [ReviewService] 리뷰 $reviewId 조회 성공');
        return Review.fromJson(response.data);
      }
      
      print('❌ [ReviewService] 예상치 못한 응답 코드: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      print('❌ [ReviewService] 리뷰 조회 실패 (DioException)');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 에러 메시지: ${e.response?.data}');
      return null;
    } catch (e) {
      print('❌ [ReviewService] 리뷰 조회 실패: $e');
      return null;
    }
  }

  /// 리뷰 삭제
  /// 
  /// 파라미터:
  /// - reviewId: 삭제할 리뷰 ID
  /// 
  /// 권한: 작성자 또는 관리자만 삭제 가능
  /// 
  /// 반환: 성공 여부 (bool)
  Future<bool> deleteReview(int reviewId) async {
    try {
      print('📝 [ReviewService] 리뷰 $reviewId 삭제 요청');
      
      final response = await _dio.delete('/reviews/$reviewId/');

      print('📝 [ReviewService] 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ [ReviewService] 리뷰 $reviewId 삭제 성공');
        return true;
      }
      
      print('❌ [ReviewService] 예상치 못한 응답 코드: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('❌ [ReviewService] 리뷰 삭제 실패 (DioException)');
      print('   - 상태 코드: ${e.response?.statusCode}');
      print('   - 에러 메시지: ${e.response?.data}');
      return false;
    } catch (e) {
      print('❌ [ReviewService] 리뷰 삭제 실패: $e');
      return false;
    }
  }

  /// 내가 작성한 리뷰 목록 조회 (전체 리뷰에서 필터링)
  /// 
  /// 파라미터:
  /// - currentUserId: 현재 로그인한 유저 ID
  /// 
  /// 반환: Review 리스트 (author.id == currentUserId인 리뷰들)
  Future<List<Review>> getMyReviews(int currentUserId) async {
    try {
      print('📝 [ReviewService] 내가 작성한 리뷰 조회 (userId: $currentUserId)');
      
      final allReviews = await getAllReviews();
      final myReviews = allReviews
          .where((review) => review.author.id == currentUserId)
          .toList();
      
      print('✅ [ReviewService] 내가 작성한 리뷰 ${myReviews.length}개 필터링 완료');
      return myReviews;
    } catch (e) {
      print('❌ [ReviewService] 내가 작성한 리뷰 조회 실패: $e');
      return [];
    }
  }

  /// 특정 거래에 대한 리뷰 존재 여부 확인
  /// 
  /// 파라미터:
  /// - tradeId: 거래 ID
  /// - authorId: 작성자 ID
  /// 
  /// 반환: 리뷰 존재 여부 (bool)
  /// 
  /// 용도: 중복 리뷰 작성 방지
  Future<bool> hasReviewForTrade(int tradeId, int authorId) async {
    try {
      print('📝 [ReviewService] 거래 $tradeId에 대한 리뷰 존재 확인 (작성자: $authorId)');
      
      final allReviews = await getAllReviews();
      final hasReview = allReviews.any((review) => 
        review.tradeRequest == tradeId && review.author.id == authorId
      );
      
      print(hasReview 
          ? '✅ [ReviewService] 거래 $tradeId에 대한 리뷰 존재함' 
          : '✅ [ReviewService] 거래 $tradeId에 대한 리뷰 없음');
      
      return hasReview;
    } catch (e) {
      print('❌ [ReviewService] 리뷰 존재 확인 실패: $e');
      return false;
    }
  }
}
