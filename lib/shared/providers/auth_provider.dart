import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, recovery }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Give Supabase time to process deep links (like password recovery) from the URL hash
    await Future.delayed(const Duration(milliseconds: 800));

    _authService.authStateStream.listen((state) async {
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _status = AuthStatus.recovery;
        notifyListeners();
        return;
      }
      
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.initialSession) {
        if (state.session != null) {
          if (_status != AuthStatus.recovery) {
            await _loadProfile();
          }
        } else {
          _status = AuthStatus.unauthenticated;
          _user = null;
          notifyListeners();
        }
      } else if (state.event == AuthChangeEvent.signedOut) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
      }
    });

    // Check initial session (fallback if stream is delayed)
    if (_status != AuthStatus.initial) return;
    
    final profile = await _authService.getCurrentProfile();
    if (_status == AuthStatus.recovery) return;

    if (profile != null) {
      _user = profile;
      _status = AuthStatus.authenticated;
    } else {
      if (_status != AuthStatus.recovery) {
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _error = 'Email atau password salah';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String nimOrNip,
    required UserRole role,
    String? prodi,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        nimOrNip: nimOrNip,
        role: role,
        prodi: prodi,
      );
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _error = 'Gagal membuat akun';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      print('SignUp Error: $e');
      _error = _parseError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminSignUp({
    required String email,
    required String password,
    required String fullName,
    required String nimOrNip,
    required UserRole role,
    String? prodi,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.adminSignUp(
        email: email,
        password: password,
        fullName: fullName,
        nimOrNip: nimOrNip,
        role: role,
        prodi: prodi,
      );
      if (user != null) {
        // Jangan ubah _user atau _status karena Admin tetap login
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
      _error = 'Gagal membuat akun user';
      // Kembalikan status ke authenticated (karena Admin)
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    } catch (e) {
      print('Admin SignUp Error: $e');
      _error = _parseError(e.toString());
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentProfile();
    
    // Do not overwrite status if a password recovery is in progress
    if (_status == AuthStatus.recovery) return;

    if (profile != null) {
      _user = profile;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email atau password salah';
    }
    if (error.contains('User already registered')) {
      return 'Terjadi kesalahan sistem';
    }
    if (error.contains('Password should be at least 6')) {
      return 'Password minimal 6 karakter';
    }
    if (error.contains('SocketException') || error.contains('network')) {
      return 'Tidak ada koneksi internet';
    }
    return error; // Return the exact error for debugging
  }

  Future<void> resolveRecovery() async {
    _status = AuthStatus.authenticated;
    await _loadProfile();
  }
}
