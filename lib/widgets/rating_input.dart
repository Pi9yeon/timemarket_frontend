// lib/widgets/rating_input.dart

import 'package:flutter/material.dart';

/// 별점 입력 위젯 (상호작용 가능)
/// 
/// 기능:
/// - 0.5 단위 별점 입력 (0.5~5.0)
/// - 탭으로 별점 선택
/// - 시각적 피드백 (색상 변경)
class RatingInput extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const RatingInput({
    Key? key,
    this.initialRating = 0.0,
    required this.onRatingChanged,
    this.size = 40.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
  }) : super(key: key);

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _handleTap(int starIndex, bool isLeftHalf) {
    setState(() {
      // starIndex: 0~4 (5개 별)
      // isLeftHalf: true면 0.5, false면 1.0
      _currentRating = starIndex + (isLeftHalf ? 0.5 : 1.0);
      widget.onRatingChanged(_currentRating);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapDown: (details) {
            // 별의 왼쪽 절반을 탭하면 0.5, 오른쪽 절반을 탭하면 1.0
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final starWidth = widget.size;
            final starLeft = index * starWidth;
            final tapPosition = localPosition.dx - starLeft;
            final isLeftHalf = tapPosition < (starWidth / 2);
            
            _handleTap(index, isLeftHalf);
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: _buildStar(index),
          ),
        );
      }),
    );
  }

  Widget _buildStar(int index) {
    final starValue = index + 1.0;
    final halfStarValue = index + 0.5;

    if (_currentRating >= starValue) {
      // 전체 별
      return Icon(
        Icons.star,
        size: widget.size,
        color: widget.activeColor,
      );
    } else if (_currentRating >= halfStarValue) {
      // 반 별
      return Icon(
        Icons.star_half,
        size: widget.size,
        color: widget.activeColor,
      );
    } else {
      // 빈 별
      return Icon(
        Icons.star_border,
        size: widget.size,
        color: widget.inactiveColor,
      );
    }
  }
}

/// 별점 표시 위젯 (읽기 전용)
/// 
/// 기능:
/// - 별점 시각화 (0.5 단위 지원)
/// - 숫자 표시 옵션
class RatingDisplay extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool showNumber;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.size = 20.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.showNumber = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return _buildStar(index);
        }),
        if (showNumber) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStar(int index) {
    final starValue = index + 1.0;
    final halfStarValue = index + 0.5;

    if (rating >= starValue) {
      // 전체 별
      return Icon(
        Icons.star,
        size: size,
        color: activeColor,
      );
    } else if (rating >= halfStarValue) {
      // 반 별
      return Icon(
        Icons.star_half,
        size: size,
        color: activeColor,
      );
    } else {
      // 빈 별
      return Icon(
        Icons.star_border,
        size: size,
        color: inactiveColor,
      );
    }
  }
}
