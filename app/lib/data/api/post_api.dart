import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error.dart';
import '../models/post_model.dart';
import 'api_client.dart';

class PostApi {
  final ApiClient _client;

  PostApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<PostModel> createPost(
    String content, {
    List<String>? mediaAssetIds,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.posts,
        data: {
          'content': content,
          if (mediaAssetIds != null && mediaAssetIds.isNotEmpty)
            'media_asset_ids': mediaAssetIds,
        },
      );
      return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<PostListResponse> getFeed({String? cursor}) async {
    try {
      final response = await _client.dio.get(
        '${ApiConstants.posts}/feed',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      return PostListResponse.fromJson(
        response.data['data'] as Map<String, dynamic>,
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

  Future<PostListResponse> getUserPosts(String userId, {String? cursor}) async {
    try {
      final response = await _client.dio.get(
        '${ApiConstants.posts}/user/$userId',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      return PostListResponse.fromJson(
        response.data['data'] as Map<String, dynamic>,
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

  Future<PostModel> getPost(String postId) async {
    try {
      final response = await _client.dio.get('${ApiConstants.posts}/$postId');
      return PostModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(
        e.response?.data,
        e.response?.statusCode ?? 500,
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _client.dio.delete('${ApiConstants.posts}/$postId');
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
