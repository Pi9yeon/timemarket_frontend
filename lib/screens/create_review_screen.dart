// lib/screens/create_review_screen.dart

import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../models/user_model.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';
import '../widgets/rating_input.dart';

/// 리뷰 작성 화면
/// 
/// 기능:
/// - 거래 완료 후 상대방에게 리뷰 작성
/// - 0.5 단위 별점 입력
/// - 리뷰 내용 입력 (optional)
/// - 자동으로 리뷰 대상자 감지 (거래 상대방)
/// 
/// 검증:
/// - 완료된 거래만 리뷰 가능
/// - 거래 참여자만 작성 가능
/// - 중복 리뷰 작성 불가
class CreateReviewScreen extends StatefulWidget {
  final TradeRequest trade;

  const CreateReviewScreen({
    Key? key,
    required this.trade,
  }) : super(key: key);

  @override
  State<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends State<CreateReviewScreen> {
  final _reviewService = ReviewService();
  final _userService = UserService();
  final _contentController = TextEditingController();
  
  double _rating = 5.0;
  bool _isLoading = false;
  User? _currentUser;
  User? _targetUser;

  @override
  void initState() {
    super.initState();
    _checkReviewStatus();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 리뷰 작성 가능 여부 및 대상자 확인
  Future<void> _checkReviewStatus() async {
    try {
      // 1. 현재 로그인한 유저 정보 가져오기
      _currentUser = await _userService.getMyInfo();
      
      if (_currentUser == null) {
        _showErrorAndClose('사용자 정보를 가져올 수 없습니다.');
        return;
      }

      // 2. 거래 완료 상태 확인
      if (widget.trade.status != 'completed') {
        _showErrorAndClose('완료된 거래만 리뷰를 작성할 수 있습니다.');
        return;
      }

      // 3. 거래 참여자 확인 및 대상자 결정
      if (_currentUser!.id == widget.trade.requester.id) {
        _targetUser = widget.trade.receiver;
      } else if (_currentUser!.id == widget.trade.receiver.id) {
        _targetUser = widget.trade.requester;
      } else {
        _showErrorAndClose('거래 참여자만 리뷰를 작성할 수 있습니다.');
        return;
      }

      // 4. 중복 리뷰 확인
      final hasReview = await _reviewService.hasReviewForTrade(
        widget.trade.id,
        _currentUser!.id,
      );

      if (hasReview) {
        _showErrorAndClose('이미 이 거래에 대한 리뷰를 작성하셨습니다.');
        return;
      }

      setState(() {});
      
      print('✅ [CreateReviewScreen] 리뷰 작성 가능');
      print('   - 작성자: ${_currentUser!.username} (ID: ${_currentUser!.id})');
      print('   - 대상자: ${_targetUser!.username} (ID: ${_targetUser!.id})');
      print('   - 거래 ID: ${widget.trade.id}');
      
    } catch (e) {
      print('❌ [CreateReviewScreen] 리뷰 상태 확인 실패: $e');
      _showErrorAndClose('리뷰 작성 중 오류가 발생했습니다.');
    }
  }

  void _showErrorAndClose(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    
    Navigator.of(context).pop();
  }

  Future<void> _submitReview() async {
    if (_currentUser == null || _targetUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 작성 준비가 되지 않았습니다.')),
      );
      return;
    }

    // 별점 검증 (0.5 단위)
    if (_rating < 0.5 || _rating > 5.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점은 0.5에서 5.0 사이여야 합니다.')),
      );
      return;
    }

    if ((_rating * 2) % 1 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점은 0.5 단위로만 입력 가능합니다.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _reviewService.createReview(
        tradeId: widget.trade.id,
        rating: _rating,
        content: _contentController.text.trim().isEmpty 
            ? null 
            : _contentController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰가 성공적으로 작성되었습니다.')),
        );
        Navigator.of(context).pop(true); // 성공 시 true 반환
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('리뷰 작성에 실패했습니다.')),
        );
      }
    } catch (e) {
      print('❌ [CreateReviewScreen] 리뷰 작성 실패: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('리뷰 작성 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _targetUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('리뷰 작성'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 거래 정보 카드
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '거래 정보',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('게시글', widget.trade.post.title),
                    const SizedBox(height: 8),
                    _buildInfoRow('거래 금액', '${widget.trade.proposedPrice.toStringAsFixed(0)}원'),
                    const SizedBox(height: 8),
                    _buildInfoRow('거래 시간', '${widget.trade.proposedHours.toStringAsFixed(1)}시간'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 리뷰 대상자 정보
            Card(
              elevation: 2,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _targetUser!.profileImageUrl != null
                          ? NetworkImage(_targetUser!.profileImageUrl!)
                          : null,
                      child: _targetUser!.profileImageUrl == null
                          ? Text(_targetUser!.username[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '리뷰 대상',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _targetUser!.username,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 별점 입력
            Text(
              '별점 *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  RatingInput(
                    initialRating: _rating,
                    onRatingChanged: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                    size: 50.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 리뷰 내용 입력
            Text(
              '리뷰 내용 (선택)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '거래 경험을 공유해주세요 (최대 500자)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 작성 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '리뷰 작성하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 안내 문구
            Center(
              child: Text(
                '* 리뷰는 작성 후 수정할 수 없습니다',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
