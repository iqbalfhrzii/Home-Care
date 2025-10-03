import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_localdatasource.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_remotedatasource.dart';
import 'package:homecare_mobile/core/error/exceptions.dart';
import 'package:homecare_mobile/shared/domain/models/auth_response.dart';
import 'package:homecare_mobile/shared/domain/models/user.dart';
import 'package:homecare_mobile/features/auth/domain/models/login_request.dart';
import 'package:homecare_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  @override
  TaskEither<Failure, User> login(LoginRequest request) {
    return TaskEither.tryCatch(
      () async {
        // Call API
        logger.i('Attempting login for email: ${request.email}');

        final response = await _remoteDataSource.login(request);
        final authResponse = AuthResponse.fromJson(response);

        // Save locally
        await _localDataSource.saveTokens(authResponse.token);
        await _localDataSource.saveUser(authResponse.user);

        logger.i('Login successful for user: ${authResponse.user.id}');
        return authResponse.user;
      },
      (error, stackTrace) {
        logger.e('Login failed: $error', error: error, stackTrace: stackTrace);

        if (error is ServerException) {
          return ServerFailure(error.message);
        }
        return ServerFailure('Unexpected error: $error');
      },
    );
  }

  @override
  TaskEither<Failure, Unit> logout() {
    return TaskEither.tryCatch(
      () async {
        await _localDataSource.deleteTokens();
        await _localDataSource.deleteUser();
        logger.i('User logged out successfully');
        return unit;
      },
      (error, stackTrace) {
        logger.e('Logout failed: $error', error: error, stackTrace: stackTrace);

        return CacheFailure('Failed to logout: $error');
      },
    );
  }

  @override
  TaskEither<Failure, Option<User>> getCurrentUser() {
    return TaskEither.tryCatch(
      () async {
        final user = await _localDataSource.getUser();
        logger.i('Fetched current user: ${user?.id}');
        return optionOf(user);
      },
      (error, stackTrace) {
        logger.e(
          'Get current user failed: $error',
          error: error,
          stackTrace: stackTrace,
        );

        return CacheFailure('Failed to get user: $error');
      },
    );
  }

  @override
  TaskEither<Failure, bool> isAuthenticated() {
    return TaskEither.tryCatch(
      () async {
        final tokens = await _localDataSource.getTokens();
        logger.i('Checked tokens: ${tokens != null ? "found" : "not found"}');
        if (tokens == null) return false;
        // return !tokens.isExpired;
        return true;
      },
      (error, stackTrace) {
        logger.e(
          'IsAuthenticated check failed: $error',
          error: error,
          stackTrace: stackTrace,
        );

        return CacheFailure('Failed to check auth: $error');
      },
    );
  }
}
