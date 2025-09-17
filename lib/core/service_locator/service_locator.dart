import 'package:get_it/get_it.dart';
import 'package:testaa/core/database/database.dart';

final class ServiceLocator {
  ServiceLocator._();
  static final locate = GetIt.instance;
  static void setup() {
    locate.registerSingleton(AppDatabase());
  }
}
