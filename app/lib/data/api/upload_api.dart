import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/errors/api_error.dart';

class UploadApi {
  final Dio _dio;

  UploadApi({Dio? dio}) : _dio = dio ?? Dio();

  Future<void> putBytes({
    required String uploadUrl,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    try {
      await _dio.put<void>(
        uploadUrl,
        data: bytes,
        options: Options(headers: {'Content-Type': mimeType}),
      );
    } on DioException catch (e) {
      throw ApiError(
        code: 'upload_failed',
        message: e.message ?? 'Upload failed',
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }
}
