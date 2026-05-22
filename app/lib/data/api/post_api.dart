import 'dart:typed_data';

import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/api_error.dart';
import '../models/post_model.dart';
import 'api_client.dart';
import 'upload_api.dart';

class PostApi {
  final ApiClient _client;
  final UploadApi _uploadApi;

  PostApi({ApiClient? client, UploadApi? uploadApi})
    : _client = client ?? ApiClient(),
      _uploadApi = uploadApi ?? UploadApi();

  Future<MediaUploadTarget> getMediaUploadUrl({
    required String filename,
    required String mimeType,
    required int size,
  }) async {
    try {
      final response = await _client.dio.post(
        '${ApiConstants.media}/upload-url',
        data: {
          'filename': filename,
          'mime_type': mimeType,
          'size': size,
          'purpose': 'posts',
        },
      );
      return MediaUploadTarget.fromJson(
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

  Future<String> uploadPostImage({
    required String filename,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    final target = await getMediaUploadUrl(
      filename: filename,
      mimeType: mimeType,
      size: bytes.length,
    );
    await _uploadApi.putBytes(
      uploadUrl: target.uploadUrl,
      bytes: bytes,
      mimeType: mimeType,
    );
    return target.mediaAssetId;
  }

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

  Future<PostModel> createReply(String postId, String content) async {
    try {
      final response = await _client.dio.post(
        '${ApiConstants.posts}/$postId/replies',
        data: {'content': content},
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

  Future<PostListResponse> getReplies(String postId) async {
    try {
      final response = await _client.dio.get(
        '${ApiConstants.posts}/$postId/replies',
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

class MediaUploadTarget {
  final String mediaAssetId;
  final String uploadUrl;
  final String publicUrl;

  const MediaUploadTarget({
    required this.mediaAssetId,
    required this.uploadUrl,
    required this.publicUrl,
  });

  factory MediaUploadTarget.fromJson(Map<String, dynamic> json) {
    return MediaUploadTarget(
      mediaAssetId: json['media_asset_id'] as String,
      uploadUrl: json['upload_url'] as String,
      publicUrl: json['public_url'] as String,
    );
  }
}
