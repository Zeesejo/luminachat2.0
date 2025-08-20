class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.code]);
}

class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);
}

class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}
