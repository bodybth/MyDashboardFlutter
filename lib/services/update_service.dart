import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // Current version embedded in the app — must match what CI writes to versionName
  // Format: "1.4.YYMMDD"  CI sets this per build; we just compare the tag string.
  static const _currentVersion = '1.4.0';

  // GitHub repo coordinates
  static const _owner = 'bodybth';
  static const _repo  = 'MyDashboardFlutter';

  static const _releasesApiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  static const _releasesPageUrl =
      'https://github.com/$_owner/$_repo/releases/latest';

  /// Returns the latest version tag string if a newer release exists,
  /// or null if the app is up-to-date / no network / any error.
  /// Never throws — always safe to call from UI.
  static Future<String?> checkForUpdate() async {
    try {
      // Connectivity check
      final lookup = await InternetAddress.lookup('api.github.com')
          .timeout(const Duration(seconds: 4));
      if (lookup.isEmpty || lookup.first.rawAddress.isEmpty) return null;

      final response = await http
          .get(Uri.parse(_releasesApiUrl),
              headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      // tag_name is like "v1.4.250227" — strip the leading "v"
      final rawTag = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
      if (rawTag.isEmpty) return null;

      // Compare: if tag != current version, it's newer (CI always bumps the date part)
      if (rawTag != _currentVersion) return rawTag;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Opens the GitHub releases page in the device browser.
  static Future<void> openReleasesPage() async {
    final uri = Uri.parse(_releasesPageUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}
