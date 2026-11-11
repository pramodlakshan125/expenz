import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(FirebaseAuthException error) => switch (error.code) {
  'invalid-email' => 'Enter a valid email address.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'Email or password is incorrect.',
  'email-already-in-use' =>
    'This email already has an account. Try signing in.',
  'weak-password' => 'Choose a stronger password with at least 6 characters.',
  'network-request-failed' =>
    'Cannot reach Firebase. Check your internet connection.',
  'operation-not-allowed' || 'password-does-not-meet-requirements' =>
    error.code == 'operation-not-allowed'
        ? 'Email/password sign-in is disabled in Firebase Authentication.'
        : 'Your password does not meet the account security requirements.',
  'too-many-requests' => 'Too many attempts. Please wait and try again.',
  'user-disabled' => 'This account has been disabled.',
  _ => 'Authentication failed (${error.code}). Please try again.',
};
