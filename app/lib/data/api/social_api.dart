import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class SocialApi {
  final ApiClient _client;

  SocialApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<void> follow(String followingId) async {
    try {
      await _client.dio.post(
        '/social/follow',
        data: {'following_id': followingId},
      );
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<void> unfollow(String followingId) async {
    try {
      await _client.dio.post(
        '/social/unfollow',
        data: {'following_id': followingId},
      );
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<bool> isFollowing(String userId) async {
    try {
      final response = await _client.dio.get(
        '/social/follow-status/$userId',
      );
      return response.data['data']['is_following'] as bool;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }
}
