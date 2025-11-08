import 'package:homecare_mobile/shared/local_db/app_database.dart';

late final AppDatabase _appDatabaseInstance = AppDatabase();

AppDatabase provideDb() => _appDatabaseInstance;
