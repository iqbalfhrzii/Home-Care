import 'package:homecare_mobile/shared/local_db/app_database.dart';
import 'package:flutter/foundation.dart';

/// Database seeder - temporarily disabled for schema v7
class DatabaseSeeder {
  final AppDatabase database;

  DatabaseSeeder(this.database);

  Future<void> seedPasienData() async {
    final existingData = await database.getAllPasiens();
    if (existingData.isNotEmpty) {
      debugPrint('Database already has \ patients');
      return;
    }
    debugPrint('Use app UI to add patients');
  }
}
