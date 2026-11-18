import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';
import 'api_providers.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final storage = ref.read(storageServiceProvider);
    final token = storage.getToken();
    final savedUser = storage.getUser();

    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      return;
    }

    if (savedUser != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: savedUser);
    }

    try {
      final authService = ref.read(authServiceProvider);
      final freshUser = await authService.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: freshUser);
    } catch (e) {
      if (savedUser == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          errorMessage: e.toString(),
        );
      }
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final authResponse = await authService.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed. Please check your network.',
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final authResponse = await authService.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed. Please check your network and credentials.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
  }

  void handleUnauthorized() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: 'Session expired. Please log in again.',
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
