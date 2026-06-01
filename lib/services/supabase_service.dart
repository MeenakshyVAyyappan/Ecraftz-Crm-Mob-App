import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://vbosonyrosxfttyoengz.supabase.co';
  static const String _supabaseAnonKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZib3Nvbnlyb3N4ZnR0eW9lbmd6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczNTU3MDQsImV4cCI6MjA5MjkzMTcwNH0.OyJKw9QvXyp3DcnR_lYkc0ID9O64bnvk521hRtW1DcE';

  /// Initializes the Supabase client connection.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }

  /// Exposes the global Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Gets the current logged-in user if available.
  static User? get currentUser => client.auth.currentUser;

  /// Signs in an existing user with email and password.
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Registers a new user with email, password, and optional user metadata.
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'full_name': name,
        'organization_id': '00000000-0000-0000-0000-000000000000',
      },
    );
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
