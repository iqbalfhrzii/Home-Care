import 'package:homecare_mobile/shared/local_db/app_database.dart';

// DISABLED - Anamnesa schema changed to JSON-based structure
// Needs complete rewrite for schema v7
class AnamnesaLocalDataSource {
  final AppDatabase _database;
  AnamnesaLocalDataSource(this._database);
  
  Future<Anamnesa?> getAnamnesaByRegistrasiId(int registrasiId) async {
    throw UnimplementedError('Anamnesa needs refactoring');
  }
}