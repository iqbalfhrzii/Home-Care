import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/features/patients/domain/models/patients_response.dart';
import 'package:homecare_mobile/features/patients/domain/repositories/patients_repository.dart';

class ReadPatientsUseCase {
  final PatientRepository repository;

  ReadPatientsUseCase(this.repository);

  TaskEither<Failure, PatientsResponse> call(int page) {
    return repository.getPatients(page);
  }
}
