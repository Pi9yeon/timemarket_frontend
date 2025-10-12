// lib/screens/review_list_screen.dart

import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_input.dart';

/// 리뷰 목록 화면
/// 
/// 두 개의 탭으로 구성:
/// 1. 받은 리뷰 (target.id == userId)
/// 2. 작성한 리뷰 (author.id == userId)
class ReviewListScreen extends StatefulWidget {
  final int? userId; // null이면 현재 로그인한 유저

  const ReviewListScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen>
    with SingleTickerProviderStateMixin {
  final _reviewService = ReviewService();
  final _userService = UserService();
  
  late TabController _tabController;
  
  List<Review> _receivedReviews = [];
  List<Review> _writtenReviews = [];
  bool _isLoadingReceived = true;
  bool _isLoadingWritten = true;
  
  User? _currentUser;
  User? _targetUser;
  int? _displayUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // 현재 로그인한 유저 정보 가져오기
      _currentUser = await _userService.getMyInfo();
      
      if (_currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다.')),
          );
        }
        return;
      }

      // userId가 지정되지 않았으면 현재 유저의 ID 사용
      _displayUserId = widget.userId ?? _currentUser!.id;
      
      // 대상 유저 정보 설정
      if (widget.userId != null && widget.userId != _currentUser!.id) {
        // 다른 유저의 리뷰를 보는 경우 (추후 확장 가능)
        _targetUser = null; // 추후 UserService.getUserById() 구현 시 설정
      } else {
        _targetUser = _currentUser;
      }

      print('📝 [ReviewListScreen] 리뷰 목록 로드');
      print('   - 현재 유저: ${_currentUser!.username} (ID: ${_currentUser!.id})');
      print('   - 표시할 유저 ID: $_displayUserId');

      // 받은 리뷰와 작성한 리뷰 동시 로드
      await Future.wait([
        _loadReceivedReviews(),
        _loadWrittenReviews(),
      ]);
      
    } catch (e) {
      print('❌ [ReviewListScreen] 데이터 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('리뷰 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _loadReceivedReviews() async {
    setState(() {
      _isLoadingReceived = true;
    });

    try {
      final reviews = await _reviewService.getReviewsForUser(_displayUserId!);
      
      if (mounted) {
        setState(() {
          _receivedReviews = reviews;
          _isLoadingReceived = false;
        });
        
        print('✅ [ReviewListScreen] 받은 리뷰 ${reviews.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ [ReviewListScreen] 받은 리뷰 로드 실패: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingReceived = false;
        });
      }
    }
  }

  Future<void> _loadWrittenReviews() async {
    setState(() {
      _isLoadingWritten = true;
    });

    try {
      final reviews = await _reviewService.getMyReviews(_displayUserId!);
      
      if (mounted) {
        setState(() {
          _writtenReviews = reviews;
          _isLoadingWritten = false;
        });
        
        print('✅ [ReviewListScreen] 작성한 리뷰 ${reviews.length}개 로드 완료');
      }
    } catch (e) {
      print('❌ [ReviewListScreen] 작성한 리뷰 로드 실패: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingWritten = false;
        });
      }
    }
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리뷰 삭제'),
        content: const Text('이 리뷰를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _reviewService.deleteReview(review.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 삭제되었습니다.')),
      );
      
      // 목록 새로고침
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 삭제에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_targetUser != null 
            ? '${_targetUser!.username}님의 리뷰' 
            : '리뷰'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              text: '받은 리뷰 (${_receivedReviews.length})',
            ),
            Tab(
              text: '작성한 리뷰 (${_writtenReviews.length})',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 받은 리뷰 탭
          _buildReviewList(
            reviews: _receivedReviews,
            isLoading: _isLoadingReceived,
            emptyMessage: '아직 받은 리뷰가 없습니다.',
            showAuthor: true,
          ),
          // 작성한 리뷰 탭
          _buildReviewList(
            reviews: _writtenReviews,
            isLoading: _isLoadingWritten,
            emptyMessage: '아직 작성한 리뷰가 없습니다.',
            showAuthor: false,
            canDelete: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList({
    required List<Review> reviews,
    required bool isLoading,
    required String emptyMessage,
    required bool showAuthor,
    bool canDelete = false,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final displayUser = showAuthor ? review.author : review.target;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 유저 정보와 별점
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: displayUser.profileImageUrl != null
                            ? NetworkImage(displayUser.profileImageUrl!)
                            : null,
                        child: displayUser.profileImageUrl == null
                            ? Text(displayUser.username[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayUser.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RatingDisplay(
                              rating: review.rating,
                              size: 16,
                              showNumber: true,
                            ),
                          ],
                        ),
                      ),
                      if (canDelete && _currentUser != null && review.author.id == _currentUser!.id)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteReview(review),
                        ),
                    ],
                  ),
                  
                  // 리뷰 내용
                  if (review.content != null && review.content!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      review.content!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  
                  // 작성일
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(review.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
