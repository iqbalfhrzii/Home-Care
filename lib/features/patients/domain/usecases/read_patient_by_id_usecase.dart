import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/domain/repositories/patients_repository.dart';

class ReadPatientByIdUseCase {
  final PatientRepository repository;

  ReadPatientByIdUseCase(this.repository);

  TaskEither<Failure, Patient> call(int id) {
    return repository.getPatientById(id);
  }
}
