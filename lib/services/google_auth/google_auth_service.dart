import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Auth Service
///
/// Service xử lý Google Sign-In native
class GoogleAuthService {
  static final GoogleAuthService _instance =
      GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  late final GoogleSignIn _googleSignIn;
  bool _isInitialized = false;

  /// Initialize Google Sign-In
  ///
  /// Note: Không cần truyền clientId cho Android vì nó được lấy từ google-services.json
  /// Chỉ cần truyền clientId nếu bạn muốn sử dụng trên Web hoặc iOS
  void initialize({String? webClientId}) {
    if (_isInitialized) return;

    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      // Sử dụng serverClientId để lấy idToken cho backend verification
      serverClientId: webClientId,
    );
    _isInitialized = true;
  }

  /// Sign in with Google
  ///
  /// Returns the ID token if successful, null otherwise
  Future<GoogleSignInResult?> signIn() async {
    try {
      // Sign out first to allow user to choose account
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account =
          await _googleSignIn.signIn();

      if (account == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication auth =
          await account.authentication;

      debugPrint('[GoogleAuth] Sign in successful');
      debugPrint('[GoogleAuth] Email: ${account.email}');
      debugPrint(
        '[GoogleAuth] ID Token: ${auth.idToken?.substring(0, 50)}...',
      );

      return GoogleSignInResult(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      debugPrint('[GoogleAuth] Sign in error: $e');
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('[GoogleAuth] Sign out successful');
    } catch (e) {
      debugPrint('[GoogleAuth] Sign out error: $e');
    }
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Get current signed in account
  GoogleSignInAccount? get currentUser =>
      _googleSignIn.currentUser;
}

/// Google Sign-In Result
class GoogleSignInResult {
  final String? idToken;
  final String? accessToken;
  final String email;
  final String? displayName;
  final String? photoUrl;

  GoogleSignInResult({
    this.idToken,
    this.accessToken,
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}
