// lib/screens/trade_history_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/trade_service.dart';
import '../models/trade_model.dart';
import '../services/user_service.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  State<TradeHistoryScreen> createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen>
    with SingleTickerProviderStateMixin {
  final TradeService _tradeService = TradeService();
  final UserService _userService = UserService();
  late TabController _tabController;
  
  List<TradeRequest> _allTrades = [];
  List<TradeRequest> _pendingTrades = [];
  List<TradeRequest> _completedTrades = [];
  List<TradeRequest> _otherTrades = [];
  
  bool _isLoading = true;
  String? _error;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _userService.getMyInfo();
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
      _loadTradeHistory();
    } else {
      setState(() {
        _error = '사용자 정보를 불러올 수 없습니다.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTradeHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trades = await _tradeService.getUserTradeHistory();
      if (trades != null) {
        setState(() {
          _allTrades = trades;
          _processTrades();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '거래내역을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '거래내역을 불러오는 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  void _processTrades() {
    // 최신순 정렬
    _allTrades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // 상태별 분류
    _pendingTrades = _allTrades.where((t) => t.status == 'pending').toList();
    _completedTrades = _allTrades.where((t) => t.status == 'completed').toList();
    _otherTrades = _allTrades.where((t) => 
      !['pending', 'completed'].contains(t.status)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('거래내역'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '전체 (${_allTrades.length})'),
            Tab(text: '대기중 (${_pendingTrades.length})'),
            Tab(text: '완료 (${_completedTrades.length})'),
            Tab(text: '거절 (${_otherTrades.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTradeHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTradeList(_allTrades),
                    _buildTradeList(_pendingTrades),
                    _buildTradeList(_completedTrades),
                    _buildTradeList(_otherTrades),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTradeHistory,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeList(List<TradeRequest> trades) {
    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '거래내역이 없습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTradeHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trades.length,
        itemBuilder: (context, index) {
          return _buildTradeCard(trades[index]);
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeRequest trade) {
    final isRequester = _currentUserId == trade.requester.id;
    final otherUser = isRequester ? trade.receiver : trade.requester;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTradeDetails(trade),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 상태와 날짜
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(trade.status),
                  Text(
                    _formatDate(trade.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 게시글 정보
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trade.post.type == 'sale' 
                          ? Colors.blue[50] 
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trade.post.type == 'sale' ? '판매' : '구매',
                      style: TextStyle(
                        fontSize: 12,
                        color: trade.post.type == 'sale' 
                            ? Colors.blue[700] 
                            : Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trade.post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 거래 상대방 정보
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: otherUser.profileImageUrl != null
                        ? NetworkImage(otherUser.profileImageUrl!)
                        : null,
                    child: otherUser.profileImageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isRequester ? "수신자" : "요청자"}: ${otherUser.nickname}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // 거래 조건
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      '제안 가격',
                      _formatPrice(trade.proposedPrice),
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      '제안 시간',
                      _formatHours(trade.proposedHours),
                      Icons.access_time,
                    ),
                  ),
                ],
              ),
              
              // 메시지가 있는 경우
              if (trade.message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trade.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String text;
    
    switch (status) {
      case 'pending':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        text = '대기중';
        break;
      case 'completed':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        text = '완료';
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        text = '거절';
        break;
      case 'cancelled':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        text = '취소';
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        text = '알 수 없음';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTradeDetails(TradeRequest trade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTradeDetailsSheet(trade),
    );
  }

  Widget _buildTradeDetailsSheet(TradeRequest trade) {
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '거래 상세정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(trade.status),
                ],
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 게시글 정보
                      _buildDetailSection(
                        '게시글 정보',
                        [
                          _buildDetailRow('제목', trade.post.title),
                          _buildDetailRow('타입', trade.post.type == 'sale' ? '판매' : '구매'),
                          _buildDetailRow('기본 가격', '${trade.post.price.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]},',
                          )}원/시간'),
                          _buildDetailRow('작성자', trade.post.author.nickname),
                        ],
                      ),
                      
                      // 거래 정보
                      _buildDetailSection(
                        '거래 정보',
                        [
                          _buildDetailRow('요청자', trade.requester.nickname),
                          _buildDetailRow('수신자', trade.receiver.nickname),
                          _buildDetailRow('제안 가격', _formatPrice(trade.proposedPrice)),
                          _buildDetailRow('제안 시간', _formatHours(trade.proposedHours)),
                          _buildDetailRow('총 예상 금액', 
                            _formatPrice(trade.proposedPrice * trade.proposedHours)),
                        ],
                      ),
                      
                      // 수락 상태
                      _buildDetailSection(
                        '수락 상태',
                        [
                          _buildDetailRow('요청자 수락', trade.requesterAccepted ? '✅ 수락' : '❌ 미수락'),
                          _buildDetailRow('수신자 수락', trade.receiverAccepted ? '✅ 수락' : '❌ 미수락'),
                        ],
                      ),
                      
                      // 메시지
                      if (trade.message.isNotEmpty)
                        _buildDetailSection(
                          '메시지',
                          [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                trade.message,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      
                      // 날짜 정보
                      _buildDetailSection(
                        '날짜 정보',
                        [
                          _buildDetailRow('생성일', _formatDateTime(trade.createdAt)),
                          _buildDetailRow('수정일', _formatDateTime(trade.updatedAt)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return '${price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}원';
  }

  String _formatHours(double hours) {
    if (hours == hours.toInt()) {
      return '${hours.toInt()}시간';
    } else {
      return '$hours시간';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일 HH:mm').format(date);
  }
}
