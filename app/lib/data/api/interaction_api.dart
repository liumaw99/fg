import 'package:dio/dio.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class InteractionApi {
  final ApiClient _client;

  InteractionApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<void> like(String postId) async {
    try {
      await _client.dio.post(
        '/interactions/like',
        data: {'post_id': postId},
      );
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<void> unlike(String postId) async {
    try {
      await _client.dio.post(
        '/interactions/unlike',
        data: {'post_id': postId},
      );
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<Map<String, dynamic>> getLikeStatus(String postId) async {
    try {
      final response = await _client.dio.get('/interactions/like-status/$postId');
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _client.dio.get('/interactions/notifications');
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      await _client.dio.post('/interactions/notifications/read-all');
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }
}
