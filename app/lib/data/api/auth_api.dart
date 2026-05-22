import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.register,
        data: {'username': username, 'email': email, 'password': password},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<void> logout(String? refreshToken) async {
    try {
      await _client.dio.post(
        ApiConstants.logout,
        data: refreshToken != null ? {'refresh_token': refreshToken} : {},
      );
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _client.dio.get(ApiConstants.me);
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }
}
