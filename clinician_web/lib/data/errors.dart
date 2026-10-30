import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any failure into one sentence a busy clinician can act on.
String friendlyError(Object error) {
  if (_looksOffline(error)) {
    return "Can't reach PhysioSathi right now. Check your internet connection and try again.";
  }
  if (error is AuthException) {
    return switch (error.code) {
      'invalid_credentials' => "That email and password don't match. Check them and try again.",
      'email_not_confirmed' => 'Please confirm your email first. Open the link we sent you, then sign in.',
      'user_already_exists' || 'email_exists' => 'An account with this email already exists. Sign in instead.',
      'weak_password' => 'Choose a stronger password: at least 8 characters, with letters and numbers.',
      'email_address_invalid' => 'That email address does not look right.',
      'over_email_send_rate_limit' => 'Too many emails were sent just now. Wait a few minutes and try again.',
      'over_request_rate_limit' => 'Too many tries. Wait a minute and try again.',
      'session_expired' || 'refresh_token_not_found' => 'Your sign-in has expired. Please sign in again.',
      _ => error.message.isEmpty ? 'Sign-in did not work. Please try again.' : error.message,
    };
  }
  if (error is PostgrestException) {
    // Our database functions raise plain sentences (code P0001) meant for people.
    if (error.code == 'P0001') return error.message;
    if (error.code == 'not_found') return error.message;
    if (error.code == '42501' || error.message.contains('row-level security')) {
      return "You don't have access to that. Try signing out and in again.";
    }
    if (error.code == 'PGRST301' || error.message.toLowerCase().contains('jwt')) {
      return 'Your sign-in has expired. Please sign in again.';
    }
    return 'The server could not do that just now. Please try again in a moment.';
  }
  return 'Something went wrong. Please try again.';
}

bool _looksOffline(Object error) {
  if (error is AuthRetryableFetchException) return true;
  final text = error.toString();
  return text.contains('ClientException') || text.contains('Failed to fetch') || text.contains('XMLHttpRequest error') || text.contains('SocketException');
}
