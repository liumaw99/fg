import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/token_storage.dart';

class AuthState extends ChangeNotifier {
  final TokenStorage _tokenStorage;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  AuthState({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _checkAuth();
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> _checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final hasToken = await _tokenStorage.hasAccessToken();
    _isAuthenticated = hasToken;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String accessToken, String refreshToken) async {
    await _tokenStorage.setAccessToken(accessToken);
    await _tokenStorage.setRefreshToken(refreshToken);
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> refreshAuth() async {
    await _checkAuth();
  }
}

final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());
