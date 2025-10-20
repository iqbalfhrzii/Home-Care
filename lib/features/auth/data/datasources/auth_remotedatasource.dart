import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/error/exceptions.dart';
import 'package:homecare_mobile/features/auth/domain/models/login_request.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(LoginRequest request);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/login', data: request.toJson());

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw const ServerException('Login failed');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Network error');
    }
  }

  @override
  Future<void> logout() async {
    final response = await _dio.post('/logout');
    if (response.statusCode == 200) {
      return Future.value();
    } else {
      throw const ServerException('Logout failed');
    }
  }
}
