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
      _error = _mapError(e);
    } catch (e) {
      _error = '注册失败，请稍后重试';
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
      _error = _mapError(e);
    } catch (e) {
      _error = '登录失败，请检查账号密码';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapError(ApiError e) {
    switch (e.code) {
      case 'invalid_credentials':
        return '邮箱或密码错误';
      case 'user_already_exists':
        return '该邮箱或用户名已被注册';
      case 'user_not_found':
        return '用户不存在';
      case 'unauthorized':
        return '登录已过期，请重新登录';
      case 'network_error':
        return '网络连接失败，请检查网络设置';
      default:
        return e.message;
    }
  }
}

final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());
