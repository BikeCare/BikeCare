import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import các trang
import '../widgets/login_page.dart';
import '../widgets/register_page.dart';
import '../widgets/register_success_page.dart';
import '../widgets/welcome_2.dart';
import '../widgets/welcome_1.dart';
import '../widgets/homepage.dart';
import '../widgets/services/traffic_fine_page.dart';
import '../widgets/maintenance_page/maintenance_tips_page.dart';
import '../widgets/profile_page.dart';
import '../widgets/history_expenses_page.dart';

class AppRoutes {
  static const trafficFine = '/traffic-fine';
  static const maintenanceTips = '/maintenance-tips';
  static const profile = '/profile';
}

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
        path: '/profile',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map<String, dynamic>) {
            return _buildSlideTransition(
              context,
              state,
              const Scaffold(body: Center(child: Text('Thiếu dữ liệu user'))),
            );
          }
          return _buildSlideTransition(
            context,
            state,
            UserProfilePage(user: extra),
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map<String, dynamic>) {
            return _buildSlideTransition(
              context,
              state,
              const Scaffold(body: Center(child: Text('Thiếu dữ liệu user'))),
            );
          }
          return _buildSlideTransition(
            context,
            state,
            HistoryExpensesPage(user: extra),
          );
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
      // Các router mới cho trang phạt nguội và mẹo bảo dưỡng
      GoRoute(
        path: AppRoutes.trafficFine,
        pageBuilder: (context, state) {
          final extra = state.extra;

          if (extra == null || extra is! Map<String, dynamic>) {
            return _buildSlideTransition(
              context,
              state,
              const Scaffold(
                body: Center(
                  child: Text(
                    'Thiếu dữ liệu user. Hãy truyền extra khi điều hướng.',
                  ),
                ),
              ),
            );
          }
          final user = extra;
          return _buildSlideTransition(
            context,
            state,
            TrafficFinePage(user: user),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.maintenanceTips,
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const MaintenanceTipsPage()),
      ),
    ],
  );
}
