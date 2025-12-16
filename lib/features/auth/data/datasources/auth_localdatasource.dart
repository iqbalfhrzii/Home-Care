import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:homecare_mobile/shared/domain/models/user.dart';

const kAccessTokenKey = 'access_token';
const kUserKey = 'user_data';

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

  const AuthLocalDataSourceImpl(this._secureStorage);

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
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: kUserKey, value: userJson);
  }

  @override
  Future<User?> getUser() async {
    final userJson = await _secureStorage.read(key: kUserKey);
    if (userJson == null) return null;
    
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    return User.fromJson(userMap);
  }

  @override
  Future<void> deleteUser() async {
    await _secureStorage.delete(key: kUserKey);
  }
}
