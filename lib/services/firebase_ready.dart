// lib/services/firebase_ready.dart
// A single shared Completer that signals when Firebase.initializeApp() has
// finished. Kept in its own file (rather than in main.dart) so services can
// import it without creating a circular dependency on main.dart, which in turn
// imports every screen and service.

import 'dart:async';

/// Completes once Firebase.initializeApp() finishes (or fails).
/// Code that needs Firebase (e.g. Auth, Storage) should await this first.
final Completer<void> firebaseReady = Completer<void>();
