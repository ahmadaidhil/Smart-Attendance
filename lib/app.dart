import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/models/attendance_model.dart';
import 'core/models/course_model.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/update_password_screen.dart';
import 'features/student/student_dashboard.dart';
import 'features/student/scan_qr_screen.dart';
import 'features/student/attendance_history_screen.dart';
import 'features/student/attendance_detail_screen.dart';
import 'features/lecturer/lecturer_dashboard.dart';
import 'features/lecturer/generate_qr_screen.dart';
import 'features/lecturer/course_recap_screen.dart';
import 'features/lecturer/student_list_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/admin/manage_users_screen.dart';
import 'features/admin/manage_courses_screen.dart';
import 'features/admin/reports_screen.dart';
import 'features/admin/system_settings_screen.dart';
import 'shared/providers/auth_provider.dart';
import 'core/models/user_model.dart';

class SmartAttendanceApp extends StatelessWidget {
  const SmartAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smart Attendance',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router(context),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.primaryMid,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.primaryMid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  GoRouter _router(BuildContext context) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (ctx, state) {
        final auth = ctx.read<AuthProvider>();
        final isLoggingIn = state.matchedLocation.startsWith('/login');
        final isUpdatingPassword = state.matchedLocation.startsWith('/update-password');
        final isRoot = state.matchedLocation == '/';

        if (auth.status == AuthStatus.initial) return null;
        if (auth.status == AuthStatus.recovery) return '/update-password';

        if (!auth.isAuthenticated && !isLoggingIn && !isRoot) return '/login';

        if (auth.isAuthenticated && (isLoggingIn || isUpdatingPassword || isRoot)) {
          final user = auth.user;
          if (user?.isMahasiswa ?? false) return '/student';
          if (user?.isDosen ?? false) return '/lecturer';
          if (user?.isAdmin ?? false) return '/admin';
        }

        return null;
      },
      refreshListenable: context.read<AuthProvider>(),
      routes: [
        // Root route
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            backgroundColor: AppColors.primaryDark,
            body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ),
        ),

        // Auth
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/update-password', builder: (_, __) => const UpdatePasswordScreen()),

        // Student routes
        GoRoute(
          path: '/student',
          builder: (_, __) => const StudentDashboard(),
          routes: [
            GoRoute(
              path: 'scan',
              builder: (_, __) => const ScanQrScreen(),
            ),
            GoRoute(
              path: 'history',
              builder: (_, __) => const AttendanceHistoryScreen(),
            ),
            GoRoute(
              path: 'attendance-detail',
              builder: (ctx, state) {
                final attendance = state.extra as AttendanceModel;
                return AttendanceDetailScreen(attendance: attendance);
              },
            ),
          ],
        ),

        // Lecturer routes
        GoRoute(
          path: '/lecturer',
          builder: (_, __) => const LecturerDashboard(),
          routes: [
            GoRoute(
              path: 'generate-qr',
              builder: (_, state) {
                final course = state.extra as CourseModel?;
                return GenerateQrScreen(course: course);
              },
            ),
            GoRoute(
              path: 'recap',
              builder: (_, __) => const CourseRecapScreen(),
            ),
            GoRoute(
              path: 'student-list',
              builder: (_, __) => const StudentListScreen(),
            ),
          ],
        ),

        // Admin routes
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminDashboard(),
          routes: [
            GoRoute(
              path: 'register',
              builder: (_, __) => const RegisterScreen(),
            ),
            GoRoute(
              path: 'users',
              builder: (_, __) => const ManageUsersScreen(),
            ),
            GoRoute(
              path: 'courses',
              builder: (_, __) => const ManageCoursesScreen(),
            ),
            GoRoute(
              path: 'reports',
              builder: (_, __) => const ReportsScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (_, __) => const SystemSettingsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
