import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

class AuthState {
  final bool isLoggedIn;
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserModel? currentUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late StorageService _storage;

  @override
  AuthState build() {
    _storage = ref.read(storageServiceProvider);

    return const AuthState();
  }

  // ----------------------------------------------------------
  // RESTORE SESSION
  // ----------------------------------------------------------

  Future<void> restoreSession() async {
    final user = await _storage.getLoggedInUser();

    if (user == null) {
      state = const AuthState();
      return;
    }

    state = AuthState(
      isLoggedIn: true,
      currentUser: user.copyWith(online: true),
    );
  }

  // ----------------------------------------------------------
  // REGISTER
  // ----------------------------------------------------------

  Future<String?> register({
    required UserModel user,
  }) async {
    state = const AuthState(
      isLoading: true,
    );

    try {
      final response = await ApiService.register(
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        password: user.password,
      );

      if (response['success'] != true) {
        final message =
            response['message'] ?? 'Registration failed.';

        state = AuthState(
          errorMessage: message,
        );

        return message;
      }

      final serverUser = response['user'];

      final registeredUser = UserModel(
        id: serverUser['_id'].toString(),
        name: serverUser['name'] ?? user.name,
        email: serverUser['email'] ?? user.email,
        phoneNumber:
            serverUser['phoneNumber'] ?? user.phoneNumber,
        password: user.password,
        initials:
            serverUser['initials'] ?? user.initials,
        online: true,
      );

      await _storage.saveLoggedInUser(registeredUser);

      state = AuthState(
        isLoggedIn: true,
        currentUser: registeredUser,
      );

      return null;
    } catch (e) {
      state = const AuthState(
        errorMessage:
            'Unable to connect to the server.',
      );

      return 'Unable to connect to the server.';
    }
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------

  Future<String?> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = const AuthState(
      isLoading: true,
    );

    try {
      String email = emailOrPhone.trim();

      // Current backend login uses email.
      if (!email.contains('@')) {
        state = const AuthState(
          errorMessage:
              'Please login using your registered email.',
        );

        return 'Please login using your registered email.';
      }

      final response = await ApiService.login(
        email: email,
        password: password,
      );

      if (response['success'] != true) {
        final message =
            response['message'] ??
                'Invalid email or password.';

        state = AuthState(
          errorMessage: message,
        );

        return message;
      }

      final serverUser = response['user'];

      final loggedInUser = UserModel(
        id: serverUser['_id'].toString(),
        name: serverUser['name'] ?? '',
        email: serverUser['email'] ?? '',
        phoneNumber:
            serverUser['phoneNumber'] ?? '',
        password: password,
        initials:
            serverUser['initials'] ?? '',
        online: true,
      );

      await _storage.saveLoggedInUser(loggedInUser);

      state = AuthState(
        isLoggedIn: true,
        currentUser: loggedInUser,
      );

      return null;
    } catch (e) {
      state = const AuthState(
        errorMessage:
            'Unable to connect to the server.',
      );

      return 'Unable to connect to the server.';
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------

  Future<void> logout() async {
    await _storage.clearLoggedInUser();

    state = const AuthState();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);