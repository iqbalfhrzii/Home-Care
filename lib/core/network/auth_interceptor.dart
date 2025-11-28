import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/storage/secure_storage.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_localdatasource.dart';

/// Adds the Sanctum token to every request.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await secureStorage.read(key: kAccessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    if (status == 401) {
      // Clear invalid token to prevent repeated unauthorized calls
      await secureStorage.delete(key: kAccessTokenKey);
      debugPrint('🔒 AuthInterceptor: 401 Unauthenticated. Token cleared. Please login again.');
    }
    handler.next(err);
  }
}
