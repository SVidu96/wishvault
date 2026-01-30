import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';

/// AuthWrapper listens to Firebase Auth state changes and automatically
/// navigates users to the appropriate screen based on their login status.
/// This provides persistent login - users stay logged in across app restarts.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show splash screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If user is logged in, fetch their data and show home page
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: authService.getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                // User is logged in and data is loaded - show home page
                return HomeScreen(user: userSnapshot.data!);
              }

              // User data not found - sign out and show login
              authService.signOut();
              return const LoginScreen();
            },
          );
        }

        // User is not logged in - show login screen
        return const LoginScreen();
      },
    );
  }
}
