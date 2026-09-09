import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../utils/offline_cache.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio dio;

  static String resolveBaseUrl() {
    if (kIsWeb) return ApiConstants.webBaseUrl;
    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return 'http://localhost:5001/api';
      }
    } catch (_) {}
    return ApiConstants.defaultBaseUrl;
  }

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await OfflineCache.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  factory DioClient() {
    _instance ??= DioClient._internal();
    return _instance!;
  }
}
