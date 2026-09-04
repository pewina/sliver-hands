import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = 'https://qfvypeedxgwlvlvgfihi.supabase.co';

  static const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFmdnlwZWVkeGd3bHZsdmdmaWhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY4NDQ5MjUsImV4cCI6MjEwMjQyMDkyNX0.H9bDaU5_jEvDn8M0kmny4nvqidrnqHe-VGYHSF6aEdc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}