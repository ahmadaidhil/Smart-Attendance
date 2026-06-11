import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../constants/supabase_constants.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) return null;
    return await getProfile(response.user!.id);
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String nimOrNip,
    required UserRole role,
    String? prodi,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role.value,
      },
    );
    if (response.user == null) return null;

    // Insert profile
    await _client.from(SupabaseConstants.profilesTable).insert({
      'id': response.user!.id,
      'email': email,
      'full_name': fullName,
      'nim_or_nip': nimOrNip,
      'role': role.value,
      'prodi': prodi,
    });

    return await getProfile(response.user!.id);
  }

  Future<UserModel?> adminSignUp({
    required String email,
    required String password,
    required String fullName,
    required String nimOrNip,
    required UserRole role,
    String? prodi,
  }) async {
    // Gunakan HTTP request langsung untuk mem-bypass SDK GoTrue.
    // Jika kita menggunakan SupabaseClient (meski temp), SDK akan mendeteksi session baru
    // dan mem-broadcast "storage" event di browser, membuat Admin ter-logout.
    
    final authUrl = Uri.parse('${SupabaseConstants.supabaseUrl}/auth/v1/signup');
    final authResponse = await http.post(
      authUrl,
      headers: {
        'apikey': SupabaseConstants.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'full_name': fullName,
          'role': role.value,
        }
      }),
    );

    if (authResponse.statusCode >= 400) {
      final errorData = jsonDecode(authResponse.body);
      throw errorData['msg'] ?? errorData['message'] ?? 'Gagal mendaftarkan pengguna';
    }

    final authData = jsonDecode(authResponse.body);
    final userId = authData['user']?['id'] as String?;
    final accessToken = authData['access_token'] as String?;

    if (userId == null || accessToken == null) {
      return null;
    }

    // Insert profile menggunakan token user baru (karena RLS auth.uid() = id)
    final postgrestUrl = Uri.parse('${SupabaseConstants.supabaseUrl}/rest/v1/${SupabaseConstants.profilesTable}');
    final insertResponse = await http.post(
      postgrestUrl,
      headers: {
        'apikey': SupabaseConstants.supabaseAnonKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'nim_or_nip': nimOrNip,
        'role': role.value,
        'prodi': prodi,
      }),
    );

    if (insertResponse.statusCode >= 400) {
      throw 'Gagal menyimpan profil pengguna';
    }

    return await getProfile(userId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getProfile(String userId) async {
    final data = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (data == null) return null;
    return UserModel.fromMap(data);
  }

  Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getProfile(user.id);
  }

  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? prodi,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (prodi != null) updates['prodi'] = prodi;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client
        .from(SupabaseConstants.profilesTable)
        .update(updates)
        .eq('id', userId);
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
