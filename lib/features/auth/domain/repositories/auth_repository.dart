import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/features/auth/domain/models/login_request.dart';
import 'package:homecare_mobile/shared/domain/models/user.dart';

abstract class AuthRepository {
  TaskEither<Failure, User> login(LoginRequest request);
  TaskEither<Failure, Unit> logout();
  TaskEither<Failure, Option<User>> getCurrentUser();
  TaskEither<Failure, bool> isAuthenticated();
}
