import 'package:fpdart/fpdart.dart';
import 'package:homecare_mobile/core/error/exceptions.dart';
import 'package:homecare_mobile/core/error/failures.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patients_remotedatasource.dart';
import 'package:homecare_mobile/features/patients/domain/models/patient.dart';
import 'package:homecare_mobile/features/patients/domain/models/patients_response.dart';
import 'package:homecare_mobile/features/patients/domain/repositories/patients_repository.dart';

class PatientRepositoryImpl implements PatientRepository {
  final PatientRemoteDataSource remoteDataSource;

  PatientRepositoryImpl(this.remoteDataSource);

  @override
  TaskEither<Failure, Patient> getPatientById(int id) {
    return TaskEither.tryCatch(
      () async {
        logger.i('Fetching patient with ID: $id');

        final patient = await remoteDataSource.getPatientById(id);

        logger.i('Successfully fetched patient: ${patient.id}');
        return patient;
      },
      (error, stackTrace) {
        logger.e(
          'Get patient by ID failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
        if (error is ServerException) {
          return ServerFailure(error.message);
        }
        return ServerFailure('Unexpected error: $error');
      },
    );
  }

  @override
  TaskEither<Failure, PatientsResponse> getPatients(int page) {
    return TaskEither.tryCatch(
      () async {
        logger.i('Fetching patients for page: $page');

        final result = await remoteDataSource.getPatients(page);

        logger.i(
          'Successfully fetched ${result.patients.length} patients for page: $page',
        );
        return PatientsResponse(
          pagination: result.pagination,
          patients: result.patients,
        );
      },
      (error, stackTrace) {
        logger.e(
          'Get patients failed: $error',
          error: error,
          stackTrace: stackTrace,
        );
        if (error is ServerException) {
          return ServerFailure(error.message);
        }
        return ServerFailure('Unexpected error: $error');
      },
    );
  }
}
