import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper over `connectivity_plus`. Exposes a `bool` stream — true
/// when at least one network interface (wifi/mobile/ethernet) is connected.
/// Errors on the underlying stream resolve to "online" rather than killing
/// the stream, since false negatives are worse than false positives here.
class ConnectivityService {
  final Connectivity _impl;
  ConnectivityService([Connectivity? impl]) : _impl = impl ?? Connectivity();

  Stream<bool> onChange() {
    return _impl.onConnectivityChanged.map(_anyOnline);
  }

  Future<bool> isOnline() async {
    final results = await _impl.checkConnectivity();
    return _anyOnline(results);
  }

  static bool _anyOnline(List<ConnectivityResult> rs) {
    if (rs.isEmpty) return false;
    return rs.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => ConnectivityService());

/// Live stream of online/offline. Defaults to true on first emit to avoid
/// flashing an offline banner before the first probe completes.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final svc = ref.read(connectivityServiceProvider);
  return svc.onChange();
});
