import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/api_error.dart';
import '../core/storage/token_storage.dart';
import '../data/api/auth_api.dart';

class AuthState extends ChangeNotifier {
  final TokenStorage _tokenStorage;
  final AuthApi _authApi;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthState({TokenStorage? tokenStorage, AuthApi? authApi})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _authApi = authApi ?? AuthApi() {
    _checkAuth();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuth() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final hasToken = await _tokenStorage.hasAccessToken();
    _isAuthenticated = hasToken;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authApi.register(username, email, password);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await _tokenStorage.setAccessToken(accessToken);
      await _tokenStorage.setRefreshToken(refreshToken);
      _isAuthenticated = true;
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authApi.login(email, password);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;

      await _tokenStorage.setAccessToken(accessToken);
      await _tokenStorage.setRefreshToken(refreshToken);
      _isAuthenticated = true;
    } on ApiError catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'Login failed. Please check your credentials.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      await _authApi.logout(refreshToken);
    } catch (_) {
      // Ignore logout API errors
    }

    await _tokenStorage.clearTokens();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshAuth() async {
    await _checkAuth();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());
