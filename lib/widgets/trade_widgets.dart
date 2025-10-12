// lib/widgets/trade_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/trade_model.dart';

// 거래 요청 카드 위젯
class TradeRequestCard extends StatelessWidget {
  final TradeRequest tradeRequest;
  final int currentUserId;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const TradeRequestCard({
    super.key,
    required this.tradeRequest,
    required this.currentUserId,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isRequester = tradeRequest.requester.id == currentUserId;
    final canRespond = tradeRequest.canUserRespond(currentUserId);
    final userAccepted = tradeRequest.isAcceptedByUser(currentUserId);
    final otherUserAccepted = isRequester 
        ? tradeRequest.receiverAccepted 
        : tradeRequest.requesterAccepted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (거래 요청 정보)
            _buildHeader(),
            const SizedBox(height: 12),
            
            // 거래 조건
            _buildTradeConditions(),
            const SizedBox(height: 12),
            
            // 메시지
            if (tradeRequest.message.isNotEmpty) ...[
              _buildMessage(),
              const SizedBox(height: 12),
            ],
            
            // 상태 및 버튼
            _buildStatusAndActions(context, canRespond, userAccepted, otherUserAccepted, isRequester),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor() {
    switch (tradeRequest.status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      case 'cancelled':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFFFFA500);
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF4A90E2)),
          ),
          child: const Text(
            '거래 요청',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A90E2),
            ),
          ),
        ),
        const Spacer(),
        Text(
          DateFormat('MM.dd HH:mm').format(tradeRequest.createdAt.toLocal()),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTradeConditions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '제안 가격',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                tradeRequest.formattedPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '예상 시간',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                tradeRequest.formattedHours,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        tradeRequest.message,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildStatusAndActions(
    BuildContext context,
    bool canRespond,
    bool userAccepted,
    bool otherUserAccepted,
    bool isRequester,
  ) {
    if (tradeRequest.isCompleted) {
      return _buildCompletedStatus();
    } else if (tradeRequest.isRejected) {
      return _buildRejectedStatus();
    } else if (tradeRequest.isCancelled) {
      return _buildCancelledStatus();
    } else {
      return _buildPendingStatus(context, canRespond, userAccepted, otherUserAccepted, isRequester);
    }
  }

  Widget _buildCompletedStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '거래가 성사되었습니다!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '거래가 거절되었습니다',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            '거래가 취소되었습니다',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingStatus(
    BuildContext context,
    bool canRespond,
    bool userAccepted,
    bool otherUserAccepted,
    bool isRequester,
  ) {
    return Column(
      children: [
        // 수락 상태 표시
        _buildAcceptanceStatus(userAccepted, otherUserAccepted, isRequester),
        const SizedBox(height: 12),
        
        // 버튼들
        if (canRespond && !userAccepted) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Text(
                    '거절',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '수락',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (userAccepted && !otherUserAccepted) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_empty, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '상대방의 응답을 기다리는 중...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAcceptanceStatus(bool userAccepted, bool otherUserAccepted, bool isRequester) {
    return Row(
      children: [
        Expanded(
          child: _buildUserStatus(
            isRequester ? '요청자' : '나',
            userAccepted,
            isRequester ? tradeRequest.requester.nickname : '나',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildUserStatus(
            isRequester ? '수신자' : '상대방',
            otherUserAccepted,
            isRequester ? tradeRequest.receiver.nickname : tradeRequest.requester.nickname,
          ),
        ),
      ],
    );
  }

  Widget _buildUserStatus(String label, bool accepted, String nickname) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accepted ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accepted ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            nickname,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                accepted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: accepted ? Colors.green[600] : Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                accepted ? '수락' : '대기중',
                style: TextStyle(
                  fontSize: 11,
                  color: accepted ? Colors.green[600] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 거래 요청 생성 다이얼로그
class CreateTradeRequestDialog extends StatefulWidget {
  final double? initialPrice;
  final double? initialHours;
  final Function(double price, double hours, String message) onSubmit;

  const CreateTradeRequestDialog({
    super.key,
    this.initialPrice,
    this.initialHours,
    required this.onSubmit,
  });

  @override
  State<CreateTradeRequestDialog> createState() => _CreateTradeRequestDialogState();
}

class _CreateTradeRequestDialogState extends State<CreateTradeRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _messageController = TextEditingController();
  
  double? _estimatedTotal;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrice != null) {
      _priceController.text = widget.initialPrice!.toInt().toString();
    }
    if (widget.initialHours != null) {
      _hoursController.text = widget.initialHours!.toString();
    }
    
    // 입력 필드 변경 감지
    _priceController.addListener(_calculateEstimatedTotal);
    _hoursController.addListener(_calculateEstimatedTotal);
    
    // 초기 계산
    _calculateEstimatedTotal();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _hoursController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  void _calculateEstimatedTotal() {
    setState(() {
      final price = double.tryParse(_priceController.text);
      final hours = double.tryParse(_hoursController.text);
      
      if (price != null && hours != null && price > 0 && hours > 0) {
        _estimatedTotal = price * hours;
      } else {
        _estimatedTotal = null;
      }
    });
  }
  
  String _formatPrice(double price) {
    final priceInt = price.toInt();
    final formatter = NumberFormat('#,###', 'ko_KR');
    return '${formatter.format(priceInt)}원';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              const Text(
                '거래 요청',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '원하는 조건을 입력해주세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // 가격 입력
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '제안 가격 (시급)',
                  hintText: '원하는 시급을 입력하세요',
                  suffixText: '원/시간',
                  helperText: '시간당 지불할 금액을 입력하세요',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가격을 입력해주세요';
                  }
                  final price = int.tryParse(value);
                  if (price == null || price <= 0) {
                    return '올바른 가격을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 시간 입력
              TextFormField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: '예상 시간',
                  hintText: '예상 소요 시간을 입력하세요',
                  suffixText: '시간',
                  helperText: '최대 24시간까지 입력 가능합니다',
                  helperStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '시간을 입력해주세요';
                  }
                  final hours = double.tryParse(value);
                  if (hours == null || hours <= 0) {
                    return '올바른 시간을 입력해주세요';
                  }
                  if (hours > 24) {
                    return '예상 시간은 24시간 이내로 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 메시지 입력
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '메시지 (선택사항)',
                  hintText: '추가로 전달하고 싶은 내용이 있다면 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value != null && value.length > 200) {
                    return '메시지는 200자 이내로 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 예상 총액 표시
              if (_estimatedTotal != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFF3E0),
                        const Color(0xFFFFE0B2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF6B35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            color: const Color(0xFFFF6B35),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '예상 총액',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatPrice(_estimatedTotal!),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF6B35),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_priceController.text}원/시간 × ${_hoursController.text}시간',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_estimatedTotal != null) const SizedBox(height: 20),
              if (_estimatedTotal == null) const SizedBox(height: 4),

              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        '요청하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      final price = double.parse(_priceController.text);
      final hours = double.parse(_hoursController.text);
      final message = _messageController.text.trim();

      widget.onSubmit(price, hours, message);
      Navigator.of(context).pop();
    }
  }
}

// 거래 요청 버튼
class TradeRequestButton extends StatelessWidget {
  final VoidCallback onPressed;

  const TradeRequestButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.handshake,
          size: 18,
          color: Colors.white,
        ),
        onPressed: onPressed,
        tooltip: '거래 요청',
      ),
    );
  }
}
