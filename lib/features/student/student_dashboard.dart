import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/attendance_provider.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/widgets/attendance_card.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/app_drawer.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await Future.wait([
      context.read<CourseProvider>().loadCoursesByStudent(user.id),
      context.read<AttendanceProvider>().loadStudentAttendances(
            studentId: user.id,
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final attendance = context.watch<AttendanceProvider>();
    final courses = context.watch<CourseProvider>();
    final summary = attendance.summary;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.white,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.adminGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  child: Text(
                                    user?.initials ?? 'U',
                                    style: AppTextStyles.h3.copyWith(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Halo, ${user?.firstName ?? 'Mahasiswa'}! 👋',
                                        style: AppTextStyles.h3,
                                      ),
                                      Text(
                                        '${DateFormatter.formatDayName(now)}, ${DateFormatter.formatDate(now)}',
                                        style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Scan QR Button
                    GestureDetector(
                      onTap: () => context.push('/student/scan'),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.successGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scan QR Absensi',
                                    style: AppTextStyles.h3,
                                  ),
                                  Text(
                                    'Tap untuk scan QR dari dosen',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                    ),

                    const SizedBox(height: 28),

                    // Stats
                    Text('Statistik Kehadiran', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                    const SizedBox(height: 14),

                    if (summary != null) ...[
                      // Percentage card
                      AttendancePercentageCard(
                        percentage: summary.attendancePercentage,
                        totalSessions: summary.totalSessions,
                        present: summary.totalPresent,
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 14),
                      // Grid stats
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.05,
                        children: [
                          _StudentStatCard(
                            value: summary.hadir.toString(),
                            label: 'Hadir',
                            color: AppColors.success,
                            icon: Icons.check_circle_rounded,
                          ),
                          _StudentStatCard(
                            value: summary.terlambat.toString(),
                            label: 'Terlambat',
                            color: AppColors.warning,
                            icon: Icons.schedule_rounded,
                          ),
                          _StudentStatCard(
                            value: summary.alpha.toString(),
                            label: 'Alpha',
                            color: AppColors.danger,
                            icon: Icons.cancel_rounded,
                          ),
                          _StudentStatCard(
                            value: summary.izin.toString(),
                            label: 'Izin/Sakit',
                            color: AppColors.info,
                            icon: Icons.info_rounded,
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),
                    ] else if (attendance.isLoading) ...[
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      ),
                    ] else if (attendance.error != null) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Error: ${attendance.error}',
                            style: AppTextStyles.body.copyWith(color: AppColors.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Fallback if summary is still null and not loading (shouldn't happen)
                      const _EmptyState(
                        icon: Icons.analytics_rounded,
                        message: 'Data statistik belum tersedia',
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Courses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mata Kuliah', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                        if (courses.courses.isNotEmpty)
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Lihat Semua',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.adminPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (courses.isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    else if (courses.courses.isEmpty)
                      _EmptyState(
                        icon: Icons.book_outlined,
                        message: 'Belum ada mata kuliah terdaftar',
                      )
                    else
                      ...courses.courses.take(5).map(
                            (c) => _CourseCard(course: c)
                                .animate()
                                .fadeIn(delay: 250.ms)
                                .slideX(begin: 0.05),
                          ),

                    const SizedBox(height: 28),

                    // Recent Attendance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Absensi Terbaru', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                        TextButton(
                          onPressed: () => context.push('/student/history'),
                          child: Text(
                            'Lihat Semua',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.accentLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (attendance.attendances.isEmpty && !attendance.isLoading)
                      _EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'Belum ada riwayat absensi',
                      )
                    else
                      ...attendance.attendances.take(5).map(
                            (a) => AttendanceCard(
                              attendance: a,
                              onTap: () => context.push(
                                '/student/attendance-detail',
                                extra: a,
                              ),
                            ).animate().fadeIn(delay: 300.ms),
                          ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.nameWithClass,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${course.code} • ${[course.lecturerName, course.lecturer2Name].where((n) => n != null && n.isNotEmpty).join(' & ')}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.grey600,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.grey200),
            ),
            child: Icon(icon, size: 40, color: AppColors.accentLight),
          ),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.body.copyWith(color: AppColors.grey500)),
        ],
      ),
    );
  }
}

class _StudentStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StudentStatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
