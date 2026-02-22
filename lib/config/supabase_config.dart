import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['VITE_SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['VITE_SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    print('Initializing Supabase with URL: $supabaseUrl');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
}
