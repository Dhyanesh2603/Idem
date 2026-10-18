import 'package:dio/dio.dart';
import 'api_exceptions.dart';

/// HTTP Client abstraction wrapping Dio with timeout controls,
/// Bearer authentication, and idempotency header injection.
class ApiClient {
  final Dio _dio;
  String? _authToken;

  ApiClient({
    String baseUrl = 'http://127.0.0.1:8000/api',
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Executes batch sync push
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    String? idempotencyKey,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final options = Options();
      if (idempotencyKey != null) {
        options.headers = {'X-Idempotency-Key': idempotencyKey};
      }
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _wrapDioException(e);
    }
  }

  /// Executes GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _wrapDioException(e);
    }
  }

  ApiException _wrapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException('Connection to synchronization server timed out');
    }

    final response = error.response;
    if (response != null) {
      if (response.statusCode == 401) {
        return const UnauthorizedException();
      }
      if (response.statusCode == 409) {
        final data = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : null;
        return ConflictException(
          message: 'Server conflict during synchronization',
          serverData: data,
        );
      }
      final msg = response.data is Map ? response.data['detail']?.toString() : null;
      return ServerException(msg ?? 'Server error', response.statusCode);
    }

    return NetworkException(error.message ?? 'Network error occurred');
  }
}
