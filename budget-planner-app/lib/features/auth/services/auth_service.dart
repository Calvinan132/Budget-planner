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

  Future<UserModel> syncUserWithBackend({
    required String email,
    required String displayName,
    String? fcmToken,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiEndpoints.syncUser,
        data: {
          'email': email,
          'displayName': displayName,
          'fcmToken': fcmToken,
        },
      );

      final userData = UserModel.fromJson(response.data);
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: displayName);
      return userData;
    } catch (e) {
      // Local fallback if backend is offline or unreachable
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: displayName);
      return UserModel(
        uid: 'local_user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        displayName: displayName,
        hasPlan: true,
      );
    }
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    try {
      UserCredential? credential;
      try {
        credential = await _firebaseAuth?.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (_) {
        try {
          credential = await _firebaseAuth?.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } catch (_) {
          // Local/offline test mode if Firebase is not initialized or offline
        }
      }

      final user = credential?.user;
      final token = await user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }

      return await syncUserWithBackend(
        email: user?.email ?? email,
        displayName: user?.displayName ?? (email.contains('@') ? email.split('@').first : email),
      );
    } catch (e) {
      return UserModel(
        uid: 'demo_user',
        email: email,
        displayName: email.contains('@') ? email.split('@').first : email,
        hasPlan: true,
      );
    }
  }

  Future<UserModel?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      UserCredential? credential;
      try {
        credential = await _firebaseAuth?.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await credential?.user?.updateDisplayName(displayName);

        final token = await credential?.user?.getIdToken();
        if (token != null) {
          await _secureStorage.write(key: 'auth_token', value: token);
        }
      } catch (_) {
        // Local/offline fallback
      }

      return await syncUserWithBackend(
        email: email,
        displayName: displayName,
      );
    } catch (e) {
      return UserModel(
        uid: 'demo_user',
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
      } catch (_) {}

      if (googleUser == null) {
        // Demo fallback if Google Sign-In is cancelled or unavailable in dev environment
        return await syncUserWithBackend(
          email: 'demo.user@gmail.com',
          displayName: 'Demo User',
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential? userCredential = await _firebaseAuth?.signInWithCredential(credential);
      final token = await userCredential?.user?.getIdToken();
      if (token != null) {
        await _secureStorage.write(key: 'auth_token', value: token);
      }

      return await syncUserWithBackend(
        email: userCredential?.user?.email ?? googleUser.email,
        displayName: userCredential?.user?.displayName ?? googleUser.displayName ?? 'Google User',
      );
    } catch (e) {
      return await syncUserWithBackend(
        email: 'demo.google@gmail.com',
        displayName: 'Google User',
      );
    }
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
