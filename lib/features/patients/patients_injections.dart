import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/utils/injections.dart';
import 'package:homecare_mobile/features/patients/data/datasources/patients_remotedatasource.dart';
import 'package:homecare_mobile/features/patients/data/repositories/patients_repository_impl.dart';
import 'package:homecare_mobile/features/patients/domain/repositories/patients_repository.dart';
import 'package:homecare_mobile/features/patients/domain/usecases/read_patient_by_id_usecase.dart';
import 'package:homecare_mobile/features/patients/domain/usecases/read_patients_usecase.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';

Future<void> initPatientInjections() async {
  // DataSources
  sl.registerFactory<PatientRemoteDataSource>(
    () => PatientRemoteDataSourceImpl(sl<Dio>()),
  );

  // Repositories
  sl.registerFactory<PatientRepository>(() => PatientRepositoryImpl(sl()));

  // UseCases
  sl.registerFactory(() => ReadPatientsUseCase(sl()));
  sl.registerFactory(() => ReadPatientByIdUseCase(sl()));

  // BLoC
  sl.registerLazySingleton(() => PatientListBloc(readPatientsUseCase: sl()));
}
