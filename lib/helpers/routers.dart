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
//import '../widgets/homepage.dart';
import '../widgets/verify_email_page.dart';
import '../garage/garage_list_page.dart';
import '../garage/garage_detail_page.dart';
import '../favorite/favorite_page.dart';
import '../vehicle/add_vehicle_page.dart';
import '../booking/booking_flow.dart';
import '../maintenance_page/maintenance_tips_page.dart';
import '../widgets/history_expenses_page.dart';
import '../widgets/services/traffic_fine_page.dart';

class AppRouter {
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

      // === GARAGE ROUTES ===
      GoRoute(
        path: '/garage/list',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            GarageListPage(user: user),
          );
        },
      ),
      GoRoute(
        path: '/garage/detail',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final garage = extra['garage'] as Map<String, dynamic>;
          final user = extra['user'] as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            GarageDetailPage(garage: garage, user: user),
          );
        },
      ),
      GoRoute(
        path: '/favorites',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            FavoritePage(user: user),
          );
        },
      ),
      GoRoute(
        path: '/add-vehicle',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            AddVehiclePage(user: user),
          );
        },
      ),

      // === BOOKING ROUTE ===
      GoRoute(
        path: '/booking',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>?;
          return _buildSlideTransition(context, state, BookingFlow(user: user));
        },
      ),

      // === MAINTENANCE TIPS ROUTES ===
      GoRoute(
        path: '/maintenance-tips',
        pageBuilder: (context, state) =>
            _buildSlideTransition(context, state, const MaintenanceTipsPage()),
      ),
      GoRoute(
        path: '/maintenance-tips/detail',
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            MaintenanceTipDetailPage(
              id: data['tip_id'] as int,
              title: data['tip_title'] as String,
              content: data['tip_content'] as String,
            ),
          );
        },
      ),

      // === HISTORY EXPENSES ROUTE ===
      GoRoute(
        path: '/history-expenses',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            HistoryExpensesPage(user: user),
          );
        },
      ),

      // === TRAFFIC FINE ROUTE ===
      GoRoute(
        path: '/traffic-fine',
        pageBuilder: (context, state) {
          final user = state.extra as Map<String, dynamic>;
          return _buildSlideTransition(
            context,
            state,
            TrafficFinePage(user: user),
          );
        },
      ),
    ],
  );
}
