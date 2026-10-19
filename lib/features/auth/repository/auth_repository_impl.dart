import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  static const String _tokenKey = 'idem_auth_token';
  static const String _userIdKey = 'idem_user_id';
  static const String _userEmailKey = 'idem_user_email';

  AuthRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final id = prefs.getString(_userIdKey);
    final email = prefs.getString(_userEmailKey);

    if (token != null && token.isNotEmpty && email != null) {
      _apiClient.setAuthToken(token);
      return UserModel(id: id ?? '', email: email, token: token);
    }
    return null;
  }

  @override
  Future<UserModel> register(String email, String password) async {
    try {
      await _apiClient.post(
        '/auth/register',
        data: {'email': email.trim(), 'password': password},
      );
      // Automatically log in after registration to retrieve access token
      return await login(email, password);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _apiClient.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      final token = data['access_token'] as String;

      _apiClient.setAuthToken(token);

      // Fetch user profile from /auth/me
      final meRes = await _apiClient.get('/auth/me');
      final meData = meRes.data as Map<String, dynamic>;
      final userId = meData['id']?.toString() ?? '';
      final userEmail = meData['email']?.toString() ?? email.trim();

      final user = UserModel(id: userId, email: userEmail, token: token);

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, userEmail);

      return user;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw UnknownApiException(e.toString());
    }
  }

  @override
  Future<UserModel?> fetchCurrentUser() async {
    if (!_apiClient.isAuthenticated) return null;
    try {
      final res = await _apiClient.get('/auth/me');
      final data = res.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey) ?? '';
      return UserModel.fromJson(data, token: token);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    _apiClient.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }
}
