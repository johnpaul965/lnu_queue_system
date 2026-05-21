// lib/core/router.dart
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/student/dashboard_screen.dart';
import '../features/student/new_request_screen.dart';
import '../features/student/request_history_screen.dart';
import '../features/student/profile_screen.dart';
import '../features/student/notifications_screen.dart';
import '../features/admin/admin_dashboard_screen.dart';
import '../features/admin/admin_requests_screen.dart';
import '../features/admin/request_detail_screen.dart';
import '../features/admin/admin_history_screen.dart';
import '../features/admin/admin_profile_screen.dart';
import '../features/superadmin/superadmin_dashboard_screen.dart';
import '../features/superadmin/superadmin_registrars_screen.dart';
import '../features/superadmin/superadmin_requests_screen.dart';
import '../features/superadmin/superadmin_profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final loc = state.matchedLocation;
    final isPublicRoute = loc == '/login' ||
        loc == '/register' ||
        loc == '/forgot-password' ||
        loc == '/reset-password';

    if (user == null && !isPublicRoute) return '/login';
    if (user != null && (loc == '/login' || loc == '/register')) {
      final role = user.userMetadata?['role'] ?? 'student';
      if (role == 'admin') return '/superadmin';
      if (role == 'staff') return '/admin';
      return '/student';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),

    GoRoute(
      path: '/student',
      builder: (_, __) => const StudentDashboardScreen(),
      routes: [
        GoRoute(path: 'new-request', builder: (_, __) => const NewRequestScreen()),
        GoRoute(path: 'history', builder: (_, __) => const RequestHistoryScreen()),
        GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // Registrar (staff role) — processes document requests
    GoRoute(
      path: '/admin',
      builder: (_, __) => const AdminDashboardScreen(),
      routes: [
        GoRoute(path: 'requests', builder: (_, __) => const AdminRequestsScreen()),
        GoRoute(path: 'history', builder: (_, __) => const AdminHistoryScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const AdminProfileScreen()),
        GoRoute(
          path: 'requests/:id',
          builder: (_, state) => RequestDetailScreen(requestId: state.pathParameters['id']!),
        ),
      ],
    ),

    // System Admin (admin role) — manages accounts and system overview
    GoRoute(
      path: '/superadmin',
      builder: (_, __) => const SuperAdminDashboardScreen(),
      routes: [
        GoRoute(path: 'registrars', builder: (_, __) => const SuperAdminRegistrarsScreen()),
        GoRoute(path: 'requests', builder: (_, __) => const SuperAdminRequestsScreen()),
        GoRoute(path: 'profile', builder: (_, __) => const SuperAdminProfileScreen()),
      ],
    ),
  ],
);
