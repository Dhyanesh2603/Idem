import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for detecting real network reachability.
///
/// Combines connectivity interface checks with lightweight DNS/socket reachability
/// probes to avoid false positives (e.g. connected to Wi-Fi router without internet access).
class ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = false;

  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  bool get isOnline => _isOnline;
  Stream<bool> get isOnlineStream => _onlineStatusController.stream;

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final online = await _probeReachability(results);
      if (online != _isOnline) {
        _isOnline = online;
        _onlineStatusController.add(_isOnline);
      }
    });

    // Initial check
    checkOnline();
  }

  /// Explicitly checks reachability right now
  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = await _probeReachability(results);
      if (online != _isOnline) {
        _isOnline = online;
        _onlineStatusController.add(_isOnline);
      }
      return _isOnline;
    } catch (_) {
      _isOnline = false;
      return false;
    }
  }

  /// Probes DNS/Socket reachability if any network interface is active
  Future<bool> _probeReachability(List<ConnectivityResult> results) async {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 3));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      // Offline or network unreachable
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _onlineStatusController.close();
  }
}
