import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import 'mock_api_interceptor.dart';
import 'mock_server_store.dart';

/// Builds the app-wide Dio instance.
///
/// Order matters: auth headers are attached first, then the mock interceptor
/// gets a chance to short-circuit before any real socket is opened.
class DioClient {
  DioClient._();

  static Dio create({
    required String? Function() tokenProvider,
    MockServerStore? mockStore,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: const {'Content-Type': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(AuthInterceptor(tokenProvider));
    if (AppConstants.useMockApi && mockStore != null) {
      dio.interceptors.add(MockApiInterceptor(mockStore));
    }
    return dio;
  }
}
