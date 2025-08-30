import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class TokenService {
  static Timer? _tokenRefreshTimer;
  static const int _tokenRefreshInterval = 3600000; // 1 hour

  /// Start token refresh timer
  static void startTokenRefresh() {
    stopTokenRefresh(); // Clear any existing timer
    _tokenRefreshTimer = Timer.periodic(
      const Duration(milliseconds: _tokenRefreshInterval),
      (_) => _refreshToken(),
    );
  }

  /// Stop token refresh timer
  static void stopTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Refresh the Firebase ID token
  static Future<void> _refreshToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force token refresh
      }
    } catch (e) {
      print('Token refresh failed: $e');
      // Let the timer continue - it will try again next interval
    }
  }
}
