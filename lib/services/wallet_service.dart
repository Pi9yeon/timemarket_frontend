// lib/services/wallet_service.dart

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://localhost:8000/api';
// 2. const String baseUrl = 'http://10.0.2.2:8000/api';
// 3. const String baseUrl = 'http://172.30.1.50:8000/api';

class WalletService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  WalletService() {
    // 모든 요청에 JWT 토큰을 포함시키기 위한 Interceptor를 설정합니다.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // 지갑 잔액을 조회하는 함수
  // API URL: /api/wallet/balance/
  Future<Map<String, dynamic>?> getWalletBalance() async {
    try {
      final response = await _dio.get('$baseUrl/wallet/balance/');
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
      await _dio.post('$baseUrl/wallet/deposit/', data: {'amount': amount.toString()});
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
      await _dio.post('$baseUrl/wallet/withdraw/', data: {'amount': amount});
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
        '$baseUrl/wallet/transfer/',
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
      final response = await _dio.get('$baseUrl/wallet/transactions/');
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
