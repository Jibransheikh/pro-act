import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://wftcgyqmhostwgmjwosf.supabase.co'; 
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndmdGNneXFtaG9zdHdnbWp3b3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NjM5MzcsImV4cCI6MjA5MzIzOTkzN30.kWYagOORf-aNKrsSD3dsUPlxsgXHqQfo-j4FIeHpqMc';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Session? get currentSession => client.auth.currentSession;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'username': username,
      },
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}