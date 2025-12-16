import 'package:get_it/get_it.dart';
import 'package:homecare_mobile/core/services/notification_service.dart';
import 'package:homecare_mobile/features/patients/data/repositories/pasien_repository.dart';
import 'package:homecare_mobile/features/patients/presentation/bloc/patient_bloc.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/registrasi_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/anamnesa_repository.dart';
import 'package:homecare_mobile/features/schedules/data/repositories/tindakan_repository.dart';
import 'package:homecare_mobile/features/reports/data/repositories/tagihan_repository.dart';
// Non-auth features will use dummy repositories (no API)

final getIt = GetIt.instance;

Future<void> initAppInjections() async {
  // Register and initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  getIt.registerSingleton<NotificationService>(notificationService);

  // Non-auth: jangan register data source API selain auth

  // Register patient repository using dummy data (no API)
  getIt.registerLazySingleton<PasienRepository>(() => PasienRepository());

  // Register other repositories as dummy (no API)
  getIt.registerLazySingleton<RegistrasiRepository>(
    () => RegistrasiRepository(),
  );
  getIt.registerLazySingleton<AnamnesaRepository>(() => AnamnesaRepository());
  getIt.registerLazySingleton<TindakanRepository>(() => TindakanRepository());
  getIt.registerLazySingleton<TagihanRepository>(() => TagihanRepository());

  // Register BLoCs
  getIt.registerLazySingleton<PatientBloc>(
    () => PatientBloc(
      repository: getIt<PasienRepository>(),
      registrasiRepository: getIt<RegistrasiRepository>(),
    ),
  );
}
