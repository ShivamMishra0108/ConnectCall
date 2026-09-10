import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/user_model.dart';

class StorageService {
  static const String _usersKey = 'registered_users';
  static const String _loggedInUserKey = 'logged_in_user';

  Future<SharedPreferences> get _prefs async {
    return SharedPreferences.getInstance();
  }

  Future<List<UserModel>> getUsers() async {
    final prefs = await _prefs;

    final data = prefs.getStringList(_usersKey) ?? [];

    return data
        .map(
          (user) => UserModel.fromJson(
            jsonDecode(user) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await _prefs;

    final users = await getUsers();

    users.add(user);

    final data = users
        .map(
          (user) => jsonEncode(user.toJson()),
        )
        .toList();

    await prefs.setStringList(_usersKey, data);
  }

  Future<UserModel?> findUser({
    required String emailOrPhone,
    required String password,
  }) async {
    final users = await getUsers();

    for (final user in users) {
      if ((user.email.toLowerCase() == emailOrPhone.toLowerCase() ||
              user.phoneNumber == emailOrPhone) &&
          user.password == password) {
        return user;
      }
    }

    return null;
  }

  Future<void> saveLoggedInUser(UserModel user) async {
    final prefs = await _prefs;

    await prefs.setString(
      _loggedInUserKey,
      jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getLoggedInUser() async {
    final prefs = await _prefs;

    final data = prefs.getString(_loggedInUserKey);

    if (data == null) return null;

    return UserModel.fromJson(
      jsonDecode(data) as Map<String, dynamic>,
    );
  }

  Future<void> clearLoggedInUser() async {
    final prefs = await _prefs;

    await prefs.remove(_loggedInUserKey);
  }
}