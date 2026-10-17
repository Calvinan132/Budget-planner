import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      String? token;
      
      // 1. Try retrieving current Firebase ID Token if logged in with Firebase
      if (Firebase.apps.isNotEmpty) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            token = await currentUser.getIdToken();
          }
        } catch (_) {}
      }

      // 2. Fallback to secure storage
      token ??= await _secureStorage.read(key: 'auth_token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Default Content-Type header
      options.headers['Content-Type'] = 'application/json';
    } catch (_) {
      // Continue even if token retrieval fails
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle token expiration / unauthorized
    }
    return handler.next(err);
  }
}
