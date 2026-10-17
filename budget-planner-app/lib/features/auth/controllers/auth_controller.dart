import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/user_model.dart';
import '../services/auth_service.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final authServiceProvider = Provider<AuthService>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthService(dioClient);
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState());

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.signInWithEmail(email, password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.signUpWithEmail(email, password, displayName);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService);
});
