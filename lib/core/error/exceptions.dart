/// Thrown by datasources; converted to a [Failure] by repositories.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class OfflineException extends AppException {
  const OfflineException([
    super.message = 'No internet connection.',
  ]);
}

class ParseException extends AppException {
  const ParseException([
    super.message = 'Unexpected response from server.',
  ]);
}
