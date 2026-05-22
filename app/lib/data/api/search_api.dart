import 'package:dio/dio.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class SearchApi {
  final ApiClient _client;

  SearchApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> search(
    String query, {
    String type = 'all',
    String? cursor,
  }) async {
    try {
      final response = await _client.dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'type': type,
          if (cursor != null) 'cursor': cursor,
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

  Future<Map<String, dynamic>> submitReport({
    String? targetUserId,
    String? targetPostId,
    required String type,
    required String reason,
  }) async {
    try {
      final response = await _client.dio.post(
        '/reports',
        data: {
          if (targetUserId != null) 'target_user_id': targetUserId,
          if (targetPostId != null) 'target_post_id': targetPostId,
          'type': type,
          'reason': reason,
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
}
