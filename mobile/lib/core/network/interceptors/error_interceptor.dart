import 'package:dio/dio.dart';

/// Error interceptor to handle and format API errors
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Format error based on type
    DioException formattedError;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        formattedError = err.copyWith(error: 'Connection timeout. Please check your internet connection.');
        break;

      case DioExceptionType.connectionError:
        formattedError = err.copyWith(error: 'Connection error. Please check your internet connection and try again.');
        break;

      case DioExceptionType.badResponse:
        // Handle different status codes
        final errorMessage = _extractErrorMessage(err.response?.data);

        formattedError = err.copyWith(error: errorMessage ?? 'An error occurred');
        break;

      case DioExceptionType.cancel:
        formattedError = err.copyWith(error: 'Request was cancelled');
        break;

      case DioExceptionType.unknown:
        formattedError = err.copyWith(error: err.error?.toString() ?? 'Network error. Please check your connection.');
        break;

      default:
        formattedError = err;
    }

    handler.next(formattedError);
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Backend returns errors in format: {"error": {"message": "...", "type": "..."}}
      if (data.containsKey('error')) {
        final error = data['error'];
        if (error is Map<String, dynamic> && error.containsKey('message')) {
          return error['message'] as String?;
        }
      }

      // Fallback: check for common error fields
      if (data.containsKey('message')) {
        return data['message'] as String?;
      }
      if (data.containsKey('detail')) {
        return data['detail'] as String?;
      }
    }

    if (data is String) {
      return data;
    }

    return null;
  }
}
