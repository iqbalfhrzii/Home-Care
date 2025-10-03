import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/shared/domain/models/user.dart';
import 'package:homecare_mobile/features/auth/domain/models/login_request.dart';
import 'package:homecare_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  TaskEither<Failure, User> call(LoginRequest request) {
    return _repository.login(request);
  }
}
