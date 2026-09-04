import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const backendUrl = String.fromEnvironment(
    'SILVERHANDS_BACKEND_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const supabaseUrl =
    'https://qfvypeedxgwlvlvgfihi.supabase.co';

  static const supabasePublishableKey =
      'sb_publishable_7TXJZT6XYft27OgUJbDVAQ_uiGMtGCj';

  /// Live Supabase mode is enabled by default.
  /// Use --dart-define=SILVERHANDS_DEMO_MODE=true only for offline demo mode.
  static const demoMode = bool.fromEnvironment(
    'SILVERHANDS_DEMO_MODE',
    defaultValue: false,
  );

  static bool get hasSupabase =>
      !demoMode &&
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty;

  static bool get isWeb => kIsWeb;
}