import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/user_model.dart';

class AuthService {
  final DioClient _dioClient;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  AuthService(this._dioClient);

  Future<UserModel?> checkAutoLogin() async {
    try {
      // 1. Check Firebase currentUser
      final fbUser = _firebaseAuth?.currentUser;
      final storedPhoto = await _secureStorage.read(key: 'user_photo');

      if (fbUser != null) {
        final email = fbUser.email ?? '';
        final displayName = fbUser.displayName ?? (email.contains('@') ? email.split('@').first : 'User');
        final photo = fbUser.photoURL ?? storedPhoto;
        return UserModel(
          uid: fbUser.uid,
          email: email,
          displayName: displayName,
          photoUrl: photo,
        );
      }

      // 2. Check stored session
      final storedUid = await _secureStorage.read(key: 'user_id');
      final storedEmail = await _secureStorage.read(key: 'user_email');
      final storedName = await _secureStorage.read(key: 'user_name');

      if (storedEmail != null && storedEmail.isNotEmpty) {
        return UserModel(
          uid: (storedUid != null && storedUid.isNotEmpty)
              ? storedUid
              : 'saved_user_${storedEmail.hashCode}',
          email: storedEmail,
          displayName: storedName ?? (storedEmail.contains('@') ? storedEmail.split('@').first : 'User'),
          photoUrl: storedPhoto,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<UserModel> syncUserWithBackend({
    required String email,
    required String displayName,
    String? photoUrl,
    String? fcmToken,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.syncUser,
        data: {
          'email': email,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'fcmToken': fcmToken,
        },
      );

      final userData = UserModel.fromJson(response.data['data'] ?? response.data);
      if (userData.uid.isNotEmpty) {
        await _secureStorage.write(key: 'user_id', value: userData.uid);
      }
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: displayName);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _secureStorage.write(key: 'user_photo', value: photoUrl);
      }
      return userData.photoUrl != null ? userData : UserModel(
        uid: userData.uid,
        email: userData.email,
        displayName: userData.displayName,
        photoUrl: photoUrl ?? userData.photoUrl,
        fcmToken: userData.fcmToken,
        hasPlan: userData.hasPlan,
      );
    } catch (e) {
      // Local fallback if backend is offline or unreachable
      final storedId = await _secureStorage.read(key: 'user_id');
      final fallbackUid = (storedId != null && storedId.isNotEmpty)
          ? storedId
          : 'user_${email.hashCode.abs()}';
      await _secureStorage.write(key: 'user_id', value: fallbackUid);
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: displayName);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _secureStorage.write(key: 'user_photo', value: photoUrl);
      }
      return UserModel(
        uid: fallbackUid,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        hasPlan: true,
      );
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential? credential;
      if (_firebaseAuth != null) {
        try {
          credential = await _firebaseAuth!.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // Nếu tài khoản chưa có trên Firebase, thử tự tạo
          try {
            credential = await _firebaseAuth!.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (_) {}
        }
      }

      final user = credential?.user;
      final token = await user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }

      final resolvedName = user?.displayName ??
          (email.contains('@') ? email.split('@').first : email);

      return await syncUserWithBackend(
        email: user?.email ?? email,
        displayName: resolvedName,
      );
    } catch (e) {
      // Offline / Direct backend sync fallback dùng đúng email người dùng đã nhập
      final generatedUid = 'user_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await _secureStorage.write(key: 'user_id', value: generatedUid);
      await _secureStorage.write(key: 'user_email', value: email);
      final resolvedName = email.contains('@') ? email.split('@').first : email;
      await _secureStorage.write(key: 'user_name', value: resolvedName);

      return UserModel(
        uid: generatedUid,
        email: email,
        displayName: resolvedName,
        hasPlan: true,
      );
    }
  }

  Future<UserModel?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      UserCredential? credential;
      if (_firebaseAuth != null) {
        try {
          credential = await _firebaseAuth!.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          await credential.user?.updateDisplayName(displayName);

          final token = await credential.user?.getIdToken();
          if (token != null) {
            await _secureStorage.write(key: 'auth_token', value: token);
          }
        } catch (_) {}
      }

      return await syncUserWithBackend(
        email: email,
        displayName: displayName,
      );
    } catch (e) {
      final generatedUid = 'user_${email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await _secureStorage.write(key: 'user_id', value: generatedUid);
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: displayName);

      return UserModel(
        uid: generatedUid,
        email: email,
        displayName: displayName,
        hasPlan: false,
      );
    }
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (err) {
        debugPrint('[AuthService] GoogleSignIn.signIn error: $err');
      }

      if (googleUser == null) {
        // Người dùng ấn hủy đăng nhập Google
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential? userCredential = await _firebaseAuth?.signInWithCredential(credential);
      final token = await userCredential?.user?.getIdToken() ?? googleAuth.idToken;
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }

      final userEmail = userCredential?.user?.email ?? googleUser.email;
      final userName = userCredential?.user?.displayName ?? googleUser.displayName ?? (userEmail.contains('@') ? userEmail.split('@').first : 'Google User');
      final userPhoto = userCredential?.user?.photoURL ?? googleUser.photoUrl;

      return await syncUserWithBackend(
        email: userEmail,
        displayName: userName,
        photoUrl: userPhoto,
      );
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Gửi email reset mật khẩu qua Firebase Auth.
  /// Throws [Exception] nếu Firebase chưa khởi tạo hoặc email không tồn tại.
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw Exception('Tính năng này yêu cầu kết nối Firebase. Vui lòng thử lại sau.');
    }
    await auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth?.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
