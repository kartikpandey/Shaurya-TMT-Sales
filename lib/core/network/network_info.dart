import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` behind a tiny interface so repositories and the
/// sync engine can be unit tested without platform channels.
class NetworkInfo {
  NetworkInfo([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
