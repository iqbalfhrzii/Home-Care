import 'package:homecare_mobile/core/storage/secure_storage.dart';
import 'package:homecare_mobile/core/utils/injections.dart';

Future<void> initStorageInjections() async {
  sl.registerSingleton(secureStorage);
}
