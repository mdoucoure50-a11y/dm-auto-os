import 'package:equatable/equatable.dart';

/// Base exception for application-level errors.
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AppException: $message';
}

final class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

final class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.code});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code});
}

final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Domain-level failure representation.
class Failure extends Equatable {
  const Failure({required this.message, this.code});

  final String message;
  final String? code;

  factory Failure.fromException(AppException exception) {
    return Failure(message: exception.message, code: exception.code);
  }

  @override
  List<Object?> get props => [message, code];
}
