// lib/services/wallet_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';

class WalletService {
  final ApiClient _apiClient = ApiClient();
  
  Dio get _dio => _apiClient.dio;


  // 지갑 잔액을 조회하는 함수
  // API URL: /api/wallet/balance/
  Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final response = await _dio.get('/wallet/balance/');
      return response.data;
    } on DioException catch (e) {
      // 개발 환경에서만 로깅
      assert(() {
        print('지갑 잔액 조회 실패: ${e.message}');
        return true;
      }());
      return null;
    }
  }

  // Time Credit을 입금하는 함수
  // API URL: /api/wallet/deposit/
  Future<bool> deposit(double amount) async {
    try {
      await _dio.post('/wallet/deposit/', data: {'amount': amount.toString()});
      return true;
    } on DioException catch (e) {
      // 개발 환경에서만 로깅
      assert(() {
        print('입금 실패: ${e.message}');
        print('에러 응답: ${e.response?.data}');
        return true;
      }());
      return false;
    }
  }

  // Time Credit을 출금하는 함수
  // API URL: /api/wallet/withdraw/
  Future<bool> withdraw(double amount) async {
    try {
      await _dio.post('/wallet/withdraw/', data: {'amount': amount});
      return true;
    } on DioException catch (e) {
      // 개발 환경에서만 로깅
      assert(() {
        print('출금 실패: ${e.message}');
        return true;
      }());
      return false;
    }
  }

  // Time Credit을 다른 사용자에게 이체하는 함수
  // API URL: /api/wallet/transfer/
  Future<bool> transfer(String recipient, double amount) async {
    try {
      await _dio.post(
        '/wallet/transfer/',
        data: {'recipient': recipient, 'amount': amount},
      );
      return true;
    } on DioException catch (e) {
      // 개발 환경에서만 로깅
      assert(() {
        print('이체 실패: ${e.message}');
        return true;
      }());
      return false;
    }
  }

  // 거래 내역 리스트를 조회하는 함수
  // API URL: /api/wallet/transactions/
  Future<List<dynamic>?> getTransactions() async {
    try {
      final response = await _dio.get('/wallet/transactions/');
      return response.data;
    } on DioException catch (e) {
      // 개발 환경에서만 로깅
      assert(() {
        print('거래 내역 조회 실패: ${e.message}');
        return true;
      }());
      return null;
    }
  }
}
