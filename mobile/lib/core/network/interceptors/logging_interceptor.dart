import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../config/app_config.dart';

/// Logging interceptor for API requests/responses
class LoggingInterceptor extends Interceptor {
  late final PrettyDioLogger _logger;

  LoggingInterceptor() {
    _logger = PrettyDioLogger(
      requestHeader: AppConfig.instance.enableLogging,
      requestBody: AppConfig.instance.enableLogging,
      responseBody: AppConfig.instance.enableLogging,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (AppConfig.instance.enableLogging) {
      _logger.onRequest(options, handler);
    } else {
      handler.next(options);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (AppConfig.instance.enableLogging) {
      _logger.onResponse(response, handler);
    } else {
      handler.next(response);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (AppConfig.instance.enableLogging) {
      _logger.onError(err, handler);
    } else {
      handler.next(err);
    }
  }
}
