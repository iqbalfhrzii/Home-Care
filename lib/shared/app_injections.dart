import 'package:get_it/get_it.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_data_source.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_local_data_source.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/shared/local_db/database_seeder.dart';

final getIt = GetIt.instance;

Future<void> initAppInjections() async {
  // Use existing configured Dio instance from core/network/dio.dart
  // It already has baseUrl, interceptors, and logger configured
  
  // Register Local Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  
  // Seed database with sample data
  final seeder = DatabaseSeeder(getIt<AppDatabase>());
  await seeder.seedPasienData();
  
  // Register Data Sources
  getIt.registerLazySingleton<PasienDataSource>(
    () => PasienDataSource(dio),
  );
  
  getIt.registerLazySingleton<PasienLocalDataSource>(
    () => PasienLocalDataSource(getIt<AppDatabase>()),
  );

  // Register repositories
  getIt.registerLazySingleton<PasienRepository>(
    () => PasienRepository(
      getIt<PasienDataSource>(),
      getIt<PasienLocalDataSource>(),
    ),
  );

  // Register BLoCs as Singleton (not Factory!)
  getIt.registerLazySingleton<PatientBloc>(
    () => PatientBloc(repository: getIt<PasienRepository>()),
  );
}
