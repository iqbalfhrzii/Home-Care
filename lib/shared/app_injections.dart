import 'package:get_it/get_it.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:homecare_mobile/core/services/notification_service.dart';
import 'package:homecare_mobile/core/services/sync_service.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_data_source.dart';
import 'package:homecare_mobile/features/patients/data/datasources/pasien_local_data_source.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/registrasi_local_datasource.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/anamnesa_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/anamnesa_local_datasource.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/anamnesa_repository.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/tindakan_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/tindakan_local_datasource.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/tindakan_repository.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/dokter_data_source.dart';
import 'package:homecare_mobile/features/schedules/data/datasources/poli_data_source.dart';
import 'package:homecare_mobile/features/reports/data/datasources/tagihan_data_source.dart';
import 'package:homecare_mobile/features/reports/data/datasources/tagihan_local_datasource.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:homecare_mobile/shared/local_db/database_seeder.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final getIt = GetIt.instance;

Future<void> initAppInjections() async {
  // Use existing configured Dio instance from core/network/dio.dart
  // It already has baseUrl, interceptors, and logger configured

  // Register and initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Register Connectivity
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());

  // Register Local Database
  getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Register Sync Service
  getIt.registerLazySingleton<SyncService>(
    () => SyncService(getIt<AppDatabase>(), dio, getIt<Connectivity>()),
  );

  // Start auto-sync service
  getIt<SyncService>().startAutoSync();

  // Seed database with sample data
  final seeder = DatabaseSeeder(getIt<AppDatabase>());
  await seeder.seedPasienData();

  // Register Data Sources
  getIt.registerLazySingleton<PasienDataSource>(() => PasienDataSource(dio));

  getIt.registerLazySingleton<PasienLocalDataSource>(
    () => PasienLocalDataSource(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<RegistrasiDataSource>(
    () => RegistrasiDataSource(dio),
  );

  getIt.registerLazySingleton<RegistrasiLocalDataSource>(
    () => RegistrasiLocalDataSource(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<AnamnesaDataSource>(
    () => AnamnesaDataSource(dio),
  );

  getIt.registerLazySingleton<AnamnesaLocalDataSource>(
    () => AnamnesaLocalDataSource(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<TindakanDataSource>(
    () => TindakanDataSource(dio),
  );

  getIt.registerLazySingleton<TindakanLocalDataSource>(
    () => TindakanLocalDataSource(getIt<AppDatabase>()),
  );

  getIt.registerLazySingleton<DokterDataSource>(() => DokterDataSource(dio));

  getIt.registerLazySingleton<PoliDataSource>(() => PoliDataSource(dio));

  getIt.registerLazySingleton<TagihanDataSource>(() => TagihanDataSource(dio));

  getIt.registerLazySingleton<TagihanLocalDataSource>(
    () => TagihanLocalDataSource(getIt<AppDatabase>()),
  );

  // Register repositories - RegistrasiRepository first karena diperlukan PasienRepository
  getIt.registerLazySingleton<RegistrasiRepository>(
    () => RegistrasiRepository(
      getIt<RegistrasiDataSource>(),
      getIt<RegistrasiLocalDataSource>(),
      getIt<PasienLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<PasienRepository>(
    () => PasienRepository(
      getIt<PasienDataSource>(),
      getIt<PasienLocalDataSource>(),
      getIt<RegistrasiRepository>(), // Inject RegistrasiRepository
    ),
  );

  getIt.registerLazySingleton<AnamnesaRepository>(
    () => AnamnesaRepository(
      getIt<AnamnesaDataSource>(),
      getIt<AnamnesaLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<TindakanRepository>(
    () => TindakanRepository(
      getIt<TindakanDataSource>(),
      getIt<TindakanLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<TagihanRepository>(
    () => TagihanRepository(
      getIt<TagihanDataSource>(),
      getIt<TagihanLocalDataSource>(),
    ),
  );

  // Register BLoCs as Singleton (not Factory!)
  getIt.registerLazySingleton<PatientBloc>(
    () => PatientBloc(repository: getIt<PasienRepository>()),
  );
}
