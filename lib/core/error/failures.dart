/// Every repository failure maps to one of these so the UI can render a
/// consistent message regardless of the underlying cause.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Your change is saved offline.',
  ]);
}

class ServerFailure extends Failure {
  ServerFailure({this.statusCode, String? message})
    : super(
        message ??
            (statusCode != null
                ? 'Server error ($statusCode).'
                : 'Something went wrong on the server.'),
      );

  final int? statusCode;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid email/phone or password.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Record not found.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}
