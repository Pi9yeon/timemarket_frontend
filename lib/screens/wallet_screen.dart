// lib/screens/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();
  double _balance = 0.0;
  bool _isLoading = true;

  // 당근마켓 스타일의 컬러 테마
  static const Color carrotOrange = Color(0xFFFF6F00);
  static const Color carrotLightOrange = Color(0xFFFFE0B2);
  static const Color carrotDarkOrange = Color(0xFFE65100);

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // 지갑 잔액을 가져오는 비동기 함수
  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
    });

    final balanceData = await _walletService.getWalletBalance();

    if (balanceData != null) {
      setState(() {
        _balance = double.tryParse(balanceData['balance'].toString()) ?? 0.0;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          '시간 포인트',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(carrotOrange),
              ),
            )
          : RefreshIndicator(
              color: carrotOrange,
              onRefresh: _fetchWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 잔액 표시 영역
                    _buildBalanceSection(),
                    const SizedBox(height: 24),
                    // 충전 UI 영역
                    _buildDepositSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // 잔액을 보여주는 섹션
  Widget _buildBalanceSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Text(
            '내 시간 포인트',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _balance.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: carrotOrange,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: carrotOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 충전 UI 섹션
  Widget _buildDepositSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '시간 포인트 충전',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // 빠른 충전 금액 버튼들
          _buildQuickAmountButtons(),
          
          const SizedBox(height: 24),
          
          // 직접 입력 필드
          _buildCustomAmountInput(),
          
          const SizedBox(height: 32),
          
          // 충전 버튼
          _buildDepositButton(),
          
          const SizedBox(height: 16),
          
          // 안내 문구
          _buildInfoText(),
        ],
      ),
    );
  }

  // 빠른 충전 금액 버튼들
  Widget _buildQuickAmountButtons() {
    final amounts = [1.0, 5.0, 10.0, 20.0, 50.0, 100.0];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: amounts.length,
      itemBuilder: (context, index) {
        final amount = amounts[index];
        return _buildAmountButton(amount);
      },
    );
  }

  // 개별 금액 버튼
  Widget _buildAmountButton(double amount) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _amountController.text = amount.toStringAsFixed(1);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '+${amount.toStringAsFixed(0)} Time',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // 직접 입력 필드
  Widget _buildCustomAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '직접 입력',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Text(
            'Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // 충전 버튼
  Widget _buildDepositButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleDeposit,
        style: ElevatedButton.styleFrom(
          backgroundColor: carrotOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          '충전하기',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // 안내 문구
  Widget _buildInfoText() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: carrotLightOrange.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: carrotDarkOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '시간 포인트는 TimeMarket에서 서비스를 거래할 때 사용됩니다.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 충전 처리 함수
  Future<void> _handleDeposit() async {
    final amountText = _amountController.text.trim();
    
    if (amountText.isEmpty) {
      _showSnackBar('충전할 금액을 입력해주세요', isError: true);
      return;
    }

    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      _showSnackBar('올바른 금액을 입력해주세요', isError: true);
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(carrotOrange),
        ),
      ),
    );

    // 충전 요청
    final response = await _walletService.deposit(amount);

    // 로딩 다이얼로그 닫기
    if (!mounted) return;
    Navigator.pop(context);

    if (response) {
      _showSnackBar('${amount.toStringAsFixed(1)} Time이 충전되었습니다');
      _amountController.clear();
      await _fetchWalletData();
      
      // 이전 화면으로 돌아갈 때 true 반환 (잔고 갱신 신호)
      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      _showSnackBar('충전에 실패했습니다. 다시 시도해주세요', isError: true);
    }
  }

  // 스낵바 표시 함수
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : carrotOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
