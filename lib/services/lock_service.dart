import 'dart:io';
import 'package:http/http.dart' as http;

class LockService {
  // Raw GitHub URL for README.md on the main branch
  // The app checks if the file contains "LOCKED" (exact, uppercase)
  static const _readmeUrl =
      'https://raw.githubusercontent.com/bodybth/MyDashboardFlutter/main/README.md';

  /// Returns true if the app should be locked (maintenance mode).
  /// - If no WiFi / internet: returns false (never block offline users)
  /// - If fetch fails for any reason: returns false (fail open)
  /// - If README contains the exact string LOCKED: returns true
  static Future<bool> isLocked() async {
    try {
      // Quick connectivity check: try to lookup github.com
      final result = await InternetAddress.lookup('raw.githubusercontent.com')
          .timeout(const Duration(seconds: 4));
      if (result.isEmpty || result.first.rawAddress.isEmpty) return false;

      final response = await http.get(Uri.parse(_readmeUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return false;

      // Check for the exact lock keyword (case-sensitive, no partial match)
      return response.body.contains('LOCKED');
    } catch (_) {
      // No internet, timeout, or any error → never block the user
      return false;
    }
  }
}
