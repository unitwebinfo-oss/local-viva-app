import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ErrorReportingService {
  static final List<Map<String, dynamic>> _pendingErrors = [];
  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _reportError(
        error: details.exception.toString(),
        stackTrace: details.stack?.toString() ?? 'No stack trace',
        type: 'flutter_error',
        context: details.context?.toString(),
      );
      // Also print to console in debug mode
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // Capture platform channel errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(
        error: error.toString(),
        stackTrace: stack.toString(),
        type: 'platform_error',
      );
      return true;
    };
  }

  static void reportError({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
  }) {
    _reportError(
      error: error.toString(),
      stackTrace: stackTrace?.toString() ?? 'No stack trace',
      type: 'caught_error',
      context: context,
    );
  }

  static Future<void> _reportError({
    required String error,
    required String stackTrace,
    required String type,
    String? context,
  }) async {
    try {
      final errorData = await _buildErrorPayload(
        error: error,
        stackTrace: stackTrace,
        type: type,
        context: context,
      );

      if (kDebugMode) {
        print('=== ERROR REPORT ===');
        print('Type: $type');
        print('Error: $error');
        print('Context: $context');
      }

      // Try to send immediately
      final success = await _sendError(errorData);

      if (!success) {
        // Queue for later if send fails
        _pendingErrors.add(errorData);
        if (_pendingErrors.length > 50) {
          _pendingErrors.removeAt(0); // Keep only last 50
        }
      }
    } catch (e) {
      // Don't let error reporting cause more errors
      if (kDebugMode) {
        print('Error reporting failed: $e');
      }
    }
  }

  static Future<Map<String, dynamic>> _buildErrorPayload({
    required String error,
    required String stackTrace,
    required String type,
    String? context,
  }) async {
    String appVersion = 'unknown';
    String deviceModel = 'unknown';
    String osVersion = 'unknown';
    String platform = 'unknown';

    try {
      appVersion = '1.0.0+5'; // TODO: Get from package_info
      deviceModel = Platform.localHostname;
      osVersion = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      platform = Platform.operatingSystem;
    } catch (e) {
      // Ignore if platform info is not available
    }

    return {
      'type': type,
      'error': error.length > 2000 ? '${error.substring(0, 2000)}...' : error,
      'stack_trace': stackTrace.length > 5000 ? '${stackTrace.substring(0, 5000)}...' : stackTrace,
      'context': context ?? 'No context',
      'app_version': appVersion,
      'device_model': deviceModel,
      'os_version': osVersion,
      'platform': platform,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static Future<bool> _sendError(Map<String, dynamic> errorData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.appErrors}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(errorData),
      ).timeout(ApiConfig.connectTimeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send error report: $e');
      }
      return false;
    }
  }

  /// Try to send any pending errors
  static Future<void> sendPendingErrors() async {
    if (_pendingErrors.isEmpty) return;

    final errorsToSend = List<Map<String, dynamic>>.from(_pendingErrors);
    _pendingErrors.clear();

    for (final errorData in errorsToSend) {
      final success = await _sendError(errorData);
      if (!success) {
        _pendingErrors.add(errorData);
        break; // Stop trying if server is still down
      }
    }
  }
}
