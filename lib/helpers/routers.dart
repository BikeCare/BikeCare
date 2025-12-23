import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import các trang

import '../widgets/login_page.dart';
import '../widgets/forgot_password.dart';
import '../widgets/register_page.dart';
import '../widgets/register_success_page.dart';
import '../widgets/welcome_2.dart';
import '../widgets/welcome_1.dart';
import '../widgets/main_screen.dart';
import '../widgets/homepage.dart';
import '../widgets/verify_email_page.dart';
import '../widgets/garage_list_page.dart';
import '../widgets/garage_detail_page.dart';
import '../widgets/favorite_page.dart';
import '../widgets/add_vehicle_page.dart';



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
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: '/homepage',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;

          return _buildSlideTransition(context, state, MainScreen(user: user));
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
        path: '/verify-email',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return VerifyEmailPage(data: data);
        },
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
        path: '/garage/list',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const GarageListPage()),
      ),
      GoRoute(
        path: '/garage/detail',
        pageBuilder: (context, state) {
          final garage = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(context, state, GarageDetailPage(garage: garage));
        },
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const FavoritePage()),
      ),
      GoRoute(
        path: '/add-vehicle',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const AddVehiclePage()),
      ),
    ],
  );
  
}
