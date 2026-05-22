import 'package:dio/dio.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class UserApi {
  final ApiClient _client;

  UserApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _client.dio.get('/users/profile');
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

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? website,
  }) async {
    try {
      final response = await _client.dio.patch(
        '/users/profile',
        data: {
          if (displayName != null) 'display_name': displayName,
          if (bio != null) 'bio': bio,
          if (location != null) 'location': location,
          if (website != null) 'website': website,
        },
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

  Future<Map<String, dynamic>> getAvatarUploadUrl({
    required String filename,
    required String mimeType,
  }) async {
    try {
      final response = await _client.dio.post(
        '/users/avatar/upload-url',
        data: {'filename': filename, 'mime_type': mimeType},
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

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      final response = await _client.dio.get('/users/$username');
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
