import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/business.dart';
import '../../../domain/entities/user.dart';
import '../../../core/providers/database_provider.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  needsOnboarding,
  authenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final Business? business;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.business,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    Business? business,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      business: business ?? this.business,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final businessRepo = _ref.read(businessRepositoryProvider);

      final hasCompletedOnboarding = await authRepo.hasCompletedOnboarding();
      if (!hasCompletedOnboarding) {
        state = const AuthState(status: AuthStatus.needsOnboarding);
        return;
      }

      final user = await authRepo.getCurrentUser();
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      final business = await businessRepo.getCurrentBusiness();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        business: business,
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> completeOnboarding() async {
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.setOnboardingCompleted();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final businessRepo = _ref.read(businessRepositoryProvider);

      final user = await authRepo.signInWithEmailPassword(email, password);
      final business = await businessRepo.getCurrentBusiness();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        business: business,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final businessRepo = _ref.read(businessRepositoryProvider);

      final user = await authRepo.registerWithEmailPassword(email, password, displayName);
      final business = await businessRepo.getCurrentBusiness();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        business: business,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithDemo() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final businessRepo = _ref.read(businessRepositoryProvider);

      final user = await authRepo.signInWithDemo();
      final business = await businessRepo.getCurrentBusiness();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        business: business,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> setupBusiness({
    required String name,
    required String ownerName,
    required String category,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final businessRepo = _ref.read(businessRepositoryProvider);
      final business = await businessRepo.setupBusiness(
        name: name,
        ownerName: ownerName,
        category: category,
        phone: phone,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        business: business,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
