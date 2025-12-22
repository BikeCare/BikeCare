import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import các trang
import '../widgets/login_page.dart';
import '../widgets/register_page.dart';
import '../widgets/register_success_page.dart';
import '../widgets/welcome_2.dart';
import '../widgets/welcome_1.dart';
import '../widgets/homepage.dart';
import '../booking/booking_flow.dart';

class AppRouter {
  // Định nghĩa hiệu ứng chuyển trang (slide từ phải sang)
  static CustomTransitionPage<void> _buildSlideTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: child,
        );
      },
    );
  }

  // Cấu hình router
  static final GoRouter router = GoRouter(
    initialLocation: '/welcome-1',
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const LoginPage()),
      ),
      GoRoute(
        path: '/homepage',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;

          return _buildSlideTransition(context, state, HomePage(user: user));
        },
      ),

      GoRoute(
        path: '/register-success',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const RegisterSuccessPage()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const RegisterPage()),
      ),
      GoRoute(
        path: '/welcome-2',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const WelcomePage2()),
      ),
      GoRoute(
        path: '/welcome-1',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const WelcomePage1()),
      ),
      GoRoute(
        path: '/booking',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>?;
          return _buildSlideTransition(context, state, BookingFlow(user: user));
        },
      ),
    ],
  );
}
