import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../providers/auth_provider.dart';
import '../../owner/owner_dashboard_screen.dart';
import 'welcome_screen.dart';

/// Root gate that routes to Welcome/Login, Customer MainShell, or Owner Dashboard
/// based on authentication state and user role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // ── 1. Checking Session / Initializing ─────────────────────────
    if (auth.status == AuthStatus.uninitialized) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.botanicalGreenLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.botanicalGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.eco,
                  color: AppColors.botanicalGreen,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.botanicalGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── 2. Authenticated: Role-Based Routing ───────────────────────
    if (auth.isAuthenticated) {
      if (auth.isOwner) {
        return const OwnerDashboardScreen();
      }
      return const MainShell();
    }

    // ── 3. Unauthenticated: Welcome Screen ─────────────────────────
    return const WelcomeScreen();
  }
}
