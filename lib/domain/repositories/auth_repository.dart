import '../entities/user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithEmailPassword(String email, String password);
  Future<AppUser> registerWithEmailPassword(String email, String password, String displayName);
  Future<AppUser> signInWithDemo();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingCompleted();
}
