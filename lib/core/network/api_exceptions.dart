/// Domain exceptions for network and API interactions.
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Network connection unavailable']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Authentication required or token expired'])
      : super(message, 401);
}

class ConflictException extends ApiException {
  final Map<String, dynamic>? serverData;
  const ConflictException({
    String message = 'Resource conflict detected',
    this.serverData,
  }) : super(message, 409);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Internal server error',
    super.statusCode = 500,
  ]);
}
