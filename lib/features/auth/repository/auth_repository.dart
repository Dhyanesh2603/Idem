import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCachedUser();
  Future<UserModel> register(String email, String password);
  Future<UserModel> login(String email, String password);
  Future<UserModel?> fetchCurrentUser();
  Future<void> logout();
}
