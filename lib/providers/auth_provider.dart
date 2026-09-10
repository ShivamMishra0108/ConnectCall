import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<String?> register({
    required UserModel user,
  }) async {
    state = const AuthState(
      isLoading: true,
    );

    final users = await _storage.getUsers();

    final emailExists = users.any(
      (existingUser) =>
          existingUser.email.toLowerCase() ==
          user.email.toLowerCase(),
    );

    if (emailExists) {
      state = const AuthState(
        errorMessage: 'Email is already registered.',
      );

      return 'Email is already registered.';
    }

    final phoneExists = users.any(
      (existingUser) =>
          existingUser.phoneNumber == user.phoneNumber,
    );

    if (phoneExists) {
      state = const AuthState(
        errorMessage: 'Mobile number is already registered.',
      );

      return 'Mobile number is already registered.';
    }

    await _storage.saveUser(user);
    await _storage.saveLoggedInUser(user);

    state = AuthState(
      isLoggedIn: true,
      currentUser: user,
    );

    return null;
  }

  Future<String?> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = const AuthState(
      isLoading: true,
    );

    final user = await _storage.findUser(
      emailOrPhone: emailOrPhone.trim(),
      password: password,
    );

    if (user == null) {
      state = const AuthState(
        errorMessage: 'Invalid email/mobile number or password.',
      );

      return 'Invalid email/mobile number or password.';
    }

    final loggedInUser = user.copyWith(
      online: true,
    );

    await _storage.saveLoggedInUser(loggedInUser);

    state = AuthState(
      isLoggedIn: true,
      currentUser: loggedInUser,
    );

    return null;
  }

  Future<void> logout() async {
    await _storage.clearLoggedInUser();

    state = const AuthState();
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);