import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Attaches the DRF token header: `Authorization: Token <token>`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenProvider);

  final String? Function() _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers[AppConstants.authHeaderKey] =
          '${AppConstants.authScheme} $token';
    }
    handler.next(options);
  }
}
