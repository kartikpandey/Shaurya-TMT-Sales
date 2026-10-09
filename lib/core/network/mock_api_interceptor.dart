import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'mock_server_store.dart';

/// Short-circuits requests to [MockServerStore] while `useMockApi` is true.
///
/// Requests the mock does not know about are passed through untouched, so the
/// same code path works against the real backend once the flag is flipped.
class MockApiInterceptor extends Interceptor {
  MockApiInterceptor(this._store);

  final MockServerStore _store;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!AppConstants.useMockApi) return handler.next(options);

    final relativePath = _relativePath(options.uri.path);
    final mock = _store.handle(
      options.method.toUpperCase(),
      relativePath,
      options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : null,
      options.uri.queryParameters,
    );

    if (mock == null) return handler.next(options);
    handler.resolve(mock.toResponse(options));
  }

  String _relativePath(String fullPath) {
    final basePath = Uri.parse(AppConstants.baseUrl).path;
    if (basePath.isNotEmpty && fullPath.startsWith(basePath)) {
      final stripped = fullPath.substring(basePath.length);
      return stripped.isEmpty ? '/' : stripped;
    }
    return fullPath;
  }
}
