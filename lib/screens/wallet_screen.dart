// lib/screens/wallet_screen.dart

import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  // 지갑 잔액과 거래 내역을 가져오는 비동기 함수
  Future<void> _fetchWalletData() async {
    setState(() {
      _isLoading = true;
    });

    final balanceData = await _walletService.getWalletBalance();
    final transactionsData = await _walletService.getTransactions();

    if (balanceData != null && transactionsData != null) {
      setState(() {
        _balance = balanceData['balance'] ?? 0.0;
        _transactions = transactionsData;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 시간 지갑')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _fetchWalletData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 지갑 잔액 표시
                      _buildBalanceCard(),
                      const SizedBox(height: 24.0),
                      // 입금, 출금, 이체 버튼
                      _buildActionButtons(),
                      const SizedBox(height: 24.0),
                      // 거래 내역 리스트
                      const Text(
                        '최근 거래 내역',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      _buildTransactionList(),
                    ],
                  ),
                ),
              ),
    );
  }

  // 잔액을 보여주는 카드 위젯
  Widget _buildBalanceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '총 보유 시간',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8.0),
            Text(
              '${_balance.toStringAsFixed(2)} 시간',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 입금, 출금, 이체 버튼 위젯
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(Icons.add_circle_outline, '입금', () {
          // TODO: 입금 팝업 또는 화면으로 이동하는 로직 구현
          _walletService.deposit(1.0);
        }),
        _buildActionButton(Icons.remove_circle_outline, '출금', () {
          // TODO: 출금 팝업 또는 화면으로 이동하는 로직 구현
          _walletService.withdraw(1.0);
        }),
        _buildActionButton(Icons.swap_horiz, '이체', () {
          // TODO: 이체 팝업 또는 화면으로 이동하는 로직 구현
          _walletService.transfer('testuser', 1.0);
        }),
      ],
    );
  }

  // 각 버튼에 대한 UI 위젯
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            radius: 30,
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // 거래 내역 리스트 위젯
  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('거래 내역이 없습니다.'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        // 거래 유형에 따라 다른 아이콘과 색상 표시
        final isDeposit = transaction['type'] == 'deposit';
        final icon = isDeposit ? Icons.arrow_downward : Icons.arrow_upward;
        final color = isDeposit ? Colors.green : Colors.red;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 1,
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              '${transaction['amount']} 시간',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            subtitle: Text(
              '${transaction['description']}\n${transaction['timestamp']}',
            ),
            trailing: const Icon(Icons.chevron_right),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
