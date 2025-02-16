// lib/core/errors/gastrobrain_exceptions.dart

/// Base exception class for all Gastrobrain-specific exceptions
class GastrobrainException implements Exception {
  final String message;

  const GastrobrainException(this.message);

  @override
  String toString() => 'GastrobrainException: $message';
}

/// Thrown when input validation fails
class ValidationException extends GastrobrainException {
  ValidationException(super.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Thrown when attempting to create a duplicate entry
class DuplicateException extends GastrobrainException {
  DuplicateException(super.message);

  @override
  String toString() => 'DuplicateException: $message';
}

/// Thrown when a requested resource is not found
class NotFoundException extends GastrobrainException {
  NotFoundException(super.message);

  @override
  String toString() => 'NotFoundException: $message';
}

// Rest of the file remains the same...
