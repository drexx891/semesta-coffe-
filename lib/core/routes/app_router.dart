import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/bloc/auth/auth_bloc.dart';
import '../../presentation/bloc/auth/auth_state.dart';
import '../../presentation/pages/splash_page.dart';
import '../../presentation/pages/login_page.dart';
import '../../presentation/pages/main_shell.dart';
import '../../presentation/pages/kds/kds_page.dart';
import '../../presentation/pages/customer/customer_display_page.dart';
import '../constants/app_colors.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/pos',
      builder: (context, state) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is AuthAuthenticated) {
              return MainShell(user: authState.user);
            }
            return const AuthGate();
          },
        );
      },
    ),
    GoRoute(
      path: '/kds',
      builder: (context, state) => const Scaffold(body: KdsPage()),
    ),
    GoRoute(
      path: '/customer',
      builder: (context, state) => const CustomerDisplayPage(),
    ),
  ],
);

/// Gate yang mengarahkan user ke halaman login atau pos
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const SplashPage();
        }
        if (state is AuthAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/pos');
            }
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        // AuthUnauthenticated, AuthError, AuthLocked
        return const LoginPage();
      },
    );
  }
}
