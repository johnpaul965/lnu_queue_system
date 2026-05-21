// lib/core/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;

  static Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await SupabaseService.getStudentByAuthId(user.id);
    } catch (_) {
      return null;
    }
  }

  static bool get isLoggedIn => currentUser != null;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
