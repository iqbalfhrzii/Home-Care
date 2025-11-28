import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homecare_mobile/core/storage/database.dart' as db;
import 'package:homecare_mobile/shared/domain/models/user.dart';

const kAccessTokenKey = 'access_token';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String tokens);
  Future<String?> getTokens();
  Future<void> deleteTokens();
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> deleteUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final db.AppDatabase _database;

  const AuthLocalDataSourceImpl(this._secureStorage, this._database);

  @override
  Future<void> saveTokens(String token) async {
    await Future.wait([
      _secureStorage.write(key: kAccessTokenKey, value: token),
    ]);
  }

  @override
  Future<String?> getTokens() async {
    return await _secureStorage.read(key: kAccessTokenKey);
  }

  @override
  Future<void> deleteTokens() async {
    await Future.wait([_secureStorage.delete(key: kAccessTokenKey)]);
  }

  @override
  Future<void> saveUser(User user) async {
    await _database
        .into(_database.users)
        .insertOnConflictUpdate(
          db.UsersCompanion.insert(
            id: user.id,
            email: user.email,
            name: user.name,
            avatarUrl: Value(user.avatarUrl),
          ),
        );
  }

  @override
  Future<User?> getUser() async {
    final query = _database.select(_database.users);
    final result = await query.getSingleOrNull();

    if (result == null) return null;

    return User(
      id: result.id,
      email: result.email,
      name: result.name,
      avatarUrl: result.avatarUrl,
    );
  }

  @override
  Future<void> deleteUser() async {
    await _database.delete(_database.users).go();
  }
}
