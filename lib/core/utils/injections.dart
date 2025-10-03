import 'package:get_it/get_it.dart';
import 'package:homecare_mobile/core/network/network_injections.dart';
import 'package:homecare_mobile/core/storage/storage_injections.dart';
import 'package:homecare_mobile/features/auth/authentication_injections.dart';
final sl = GetIt.instance;
Future<void> initInjections() async {
  await initStorageInjections();
  await initAppInjections();
  await initNetworkInjections();
}
