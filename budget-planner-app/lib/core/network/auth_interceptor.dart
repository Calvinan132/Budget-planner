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

      // Lấy userId thực tế của người dùng:
      // Ưu tiên Firebase Auth UID -> Stored user_id
      String? actualUid;
      String? actualEmail;
      if (Firebase.apps.isNotEmpty) {
        try {
          final currentUser = FirebaseAuth.instance.currentUser;
          actualUid = currentUser?.uid;
          actualEmail = currentUser?.email;
        } catch (_) {}
      }
      actualUid ??= await _secureStorage.read(key: 'user_id');
      actualEmail ??= await _secureStorage.read(key: 'user_email');

      final effectiveUserId = (actualUid != null && actualUid.isNotEmpty)
          ? actualUid
          : 'user_${actualEmail?.hashCode.abs() ?? "dev"}';

      // Gửi cả x-dev-user-id, x-user-id và x-user-email để backend nhận diện chuẩn xác tài khoản người dùng
      options.headers['x-dev-user-id'] = effectiveUserId;
      options.headers['x-user-id'] = effectiveUserId;
      if (actualEmail != null && actualEmail.isNotEmpty) {
        options.headers['x-user-email'] = actualEmail;
      }

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
