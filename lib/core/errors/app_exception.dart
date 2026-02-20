import 'dart:io';
import 'package:dio/dio.dart';

/// The type of error that occurred, used to show contextual UI.
enum AppErrorType {
  /// No internet connection (airplane mode, Wi-Fi off, etc.)
  noInternet,

  /// Server is unreachable or timed out
  serverUnreachable,

  /// API returned an error status code
  serverError,

  /// Request timed out
  timeout,

  /// Location services or permissions issue
  locationError,

  /// Generic / unknown error
  unknown,
}

/// A user-friendly exception wrapper that classifies raw exceptions
/// into a finite set of [AppErrorType]s. The UI layer uses the type
/// to pick the right illustration, message, and call-to-action.
class AppException implements Exception {
  final AppErrorType type;
  final String? debugMessage;

  const AppException({required this.type, this.debugMessage});

  /// Factory that inspects the raw exception and returns a classified
  /// [AppException].
  factory AppException.from(Object error) {
    if (error is AppException) return error;

    // Dio-specific errors
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException(
            type: AppErrorType.timeout,
            debugMessage: error.message,
          );
        case DioExceptionType.connectionError:
          return AppException(
            type: AppErrorType.noInternet,
            debugMessage: error.message,
          );
        case DioExceptionType.badResponse:
          return AppException(
            type: AppErrorType.serverError,
            debugMessage:
                'Status ${error.response?.statusCode}: ${error.message}',
          );
        default:
          // Check inner error for SocketException
          if (error.error is SocketException) {
            return AppException(
              type: AppErrorType.noInternet,
              debugMessage: error.message,
            );
          }
          return AppException(
            type: AppErrorType.serverUnreachable,
            debugMessage: error.message,
          );
      }
    }

    // Raw SocketException (no internet)
    if (error is SocketException) {
      return AppException(
        type: AppErrorType.noInternet,
        debugMessage: error.message,
      );
    }

    // Check string-based errors (e.g. from Future.error in LocationService)
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection error') ||
        errorStr.contains('no address associated') ||
        errorStr.contains('network is unreachable')) {
      return AppException(
        type: AppErrorType.noInternet,
        debugMessage: error.toString(),
      );
    }

    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return AppException(
        type: AppErrorType.timeout,
        debugMessage: error.toString(),
      );
    }

    if (errorStr.contains('location') || errorStr.contains('permission')) {
      return AppException(
        type: AppErrorType.locationError,
        debugMessage: error.toString(),
      );
    }

    return AppException(
      type: AppErrorType.unknown,
      debugMessage: error.toString(),
    );
  }

  @override
  String toString() => 'AppException($type, $debugMessage)';
}
