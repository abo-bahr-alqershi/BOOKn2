import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../services/connectivity_service.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected async {
    try {
      return await connectionChecker.hasConnection;
    } catch (_) {
      // Fallback to app-level connectivity check to avoid IPv6 DNS issues
      try {
        return await ConnectivityService().checkConnection();
      } catch (_) {
        return false;
      }
    }
  }
}