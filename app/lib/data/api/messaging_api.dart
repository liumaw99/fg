import 'package:dio/dio.dart';
import '../../core/errors/api_error.dart';
import 'api_client.dart';

class MessagingApi {
  final ApiClient _client;

  MessagingApi({ApiClient? client}) : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> createConversation(String participantId) async {
    try {
      final response = await _client.dio.post(
        '/conversations',
        data: {'participant_id': participantId},
      );
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<Map<String, dynamic>> getConversations() async {
    try {
      final response = await _client.dio.get('/conversations');
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
    required String clientMessageId,
  }) async {
    try {
      final response = await _client.dio.post(
        '/messages',
        data: {
          'conversation_id': conversationId,
          'content': content,
          'client_message_id': clientMessageId,
        },
      );
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }

  Future<Map<String, dynamic>> getMessages(String conversationId) async {
    try {
      final response = await _client.dio.get('/conversations/$conversationId/messages');
      return response.data['data'] as Map<String, dynamic>;
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw ApiError.fromResponse(e.response?.data, e.response?.statusCode ?? 500);
    }
  }
}
