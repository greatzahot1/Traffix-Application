import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {Object? data, String? tag}) {
    if (kDebugMode) {
      final timeStamp = DateTime.now().toIso8601String();
      final logTag = tag != null ? '[$tag]' : '';
      final logData = data != null ? ' - $data' : '';
      print('$timeStamp $logTag: $message$logData');
    }
  }

  static void logError(dynamic error, {String? tag, StackTrace? stackTrace}) {
    log('Error: $error', data: stackTrace ?? '', tag: tag);
  }
}
