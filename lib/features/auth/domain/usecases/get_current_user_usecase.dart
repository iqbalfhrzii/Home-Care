import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/shared/domain/models/user.dart';
import 'package:homecare_mobile/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  const GetCurrentUserUseCase(this._repository);

  TaskEither<Failure, Option<User>> call() {
    return _repository.getCurrentUser();
  }
}
