import 'package:homecare_mobile/core/utils/injections.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_localdatasource.dart';
import 'package:homecare_mobile/features/auth/data/datasources/auth_remotedatasource.dart';
import 'package:homecare_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:homecare_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:homecare_mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:homecare_mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:homecare_mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> initAuthInjections() async {
  sl
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    )
    ..registerFactory<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(sl(), sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl(), sl()),
    )
    ..registerFactory(() => LoginUseCase(sl()))
    ..registerFactory(() => LogoutUseCase(sl()))
    ..registerFactory(() => GetCurrentUserUseCase(sl()))
    ..registerLazySingleton(
      () => AuthBloc(
        loginUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
      ),
    );
}
