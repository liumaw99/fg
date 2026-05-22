class ApiError implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiError({required this.code, required this.message, this.statusCode});

  factory ApiError.fromResponse(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      return ApiError(
        code: data['code']?.toString() ?? 'unknown_error',
        message: data['message']?.toString() ?? 'Unknown error occurred',
        statusCode: statusCode,
      );
    }
    return ApiError(
      code: 'unknown_error',
      message: 'Unknown error occurred',
      statusCode: statusCode,
    );
  }

  factory ApiError.network() {
    return const ApiError(
      code: 'network_error',
      message: 'Network connection failed. Please check your internet.',
    );
  }

  factory ApiError.unauthorized() {
    return const ApiError(
      code: 'unauthorized',
      message: 'Session expired. Please login again.',
    );
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}
