import 'package:dio/dio.dart';
import 'package:homecare_mobile/core/network/dio.dart';
import 'package:homecare_mobile/core/utils/injections.dart';

Future<void> initNetworkInjections() async {
  sl.registerSingleton<Dio>(dio);
}
