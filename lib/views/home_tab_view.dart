import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';

class HomeTabView extends StatelessWidget {
  final UserModel user;

  const HomeTabView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // User Avatar with animation
              Hero(
                tag: 'user_avatar',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Welcome Message
              Text(
                'Welcome,',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.displayName,
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // User Email Chip
              Chip(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                avatar: Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  user.email,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Info Card
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Secure Identity',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your account is linked to Google and your data is safely stored in our vault.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
