import 'package:flutter_test/flutter_test.dart';
import 'package:obsidian_slate/features/auth/models/user_model.dart';
import 'package:obsidian_slate/features/auth/providers/auth_providers.dart';

void main() {
  group('Auth Model and State Tests', () {
    test('UserModel serialization and deserialization', () {
      final user = const UserModel(
        id: 'usr_123',
        email: 'developer@workstation.io',
        token: 'jwt_token_sample',
      );

      final json = user.toJson();
      expect(json['id'], 'usr_123');
      expect(json['email'], 'developer@workstation.io');
      expect(json['token'], 'jwt_token_sample');

      final reconstructed = UserModel.fromJson(json);
      expect(reconstructed.id, 'usr_123');
      expect(reconstructed.email, 'developer@workstation.io');
      expect(reconstructed.token, 'jwt_token_sample');
    });

    test('AuthState initial state and authenticated status', () {
      const state = AuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);

      final user = const UserModel(
        id: 'usr_999',
        email: 'test@idem.io',
        token: 'token_abc',
      );

      final loggedInState = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      );

      expect(loggedInState.isAuthenticated, isTrue);
      expect(loggedInState.user?.email, 'test@idem.io');
    });

    test('AuthState error state captures message correctly', () {
      const state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Invalid credentials provided.',
      );

      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, 'Invalid credentials provided.');
    });
  });
}
