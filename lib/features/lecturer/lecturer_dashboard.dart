import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/course_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/attendance_provider.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/stat_card.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    
    _isDataLoaded = true;
    
    // Memberikan sedikit waktu agar token autentikasi Supabase siap sepenuhnya
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    
    await context.read<CourseProvider>().loadCoursesByLecturer(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final courses = context.watch<CourseProvider>();
    final now = DateTime.now();

    if (user != null && !_isDataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.primaryMid,
        child: CustomScrollView(
          slivers: [
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
              flexibleSpace: FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.adminPrimary, Color(0xFF600000)],
                      ),
                    ),
                    child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Halo, ${user?.firstName ?? 'Dosen'}! 👨‍🏫',
                            style: AppTextStyles.h2,
                          ),
                          Text(
                            '${DateFormatter.formatDayName(now)}, ${DateFormatter.formatDate(now)}',
                            style: AppTextStyles.bodySmall,
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
                    // Quick actions
                    Text('Aksi Cepat', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.qr_code_2_rounded,
                            label: 'Buka Sesi\nAbsensi',
                            color: AppColors.adminPrimary,
                            onTap: () => context.push('/lecturer/generate-qr'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'Rekap\nKehadiran',
                            color: AppColors.adminPrimary,
                            onTap: () => context.push('/lecturer/recap'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.people_rounded,
                            label: 'Daftar\nMahasiswa',
                            color: AppColors.adminPrimary,
                            onTap: () => context.push('/lecturer/student-list'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 28),
                    // Courses
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mata Kuliah Saya', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.adminLight,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: AppColors.adminPrimary.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${courses.courses.length} MK',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.adminPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (courses.isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                        ),
                      )
                    else if (courses.courses.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 48,
                                color: AppColors.grey700,
                              ),
                              const SizedBox(height: 12),
                                Text(
                                  courses.error != null 
                                      ? 'Gagal memuat: ${courses.error}'
                                      : 'Belum ada mata kuliah',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: courses.error != null 
                                        ? AppColors.dangerLight 
                                        : AppColors.grey600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...courses.courses.map(
                        (c) => _LecturerCourseCard(
                          course: c,
                          onTap: () => context.push(
                            '/lecturer/generate-qr',
                            extra: c,
                          ),
                        ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminPrimary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.adminLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.adminPrimary, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerCourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _LecturerCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.adminPrimary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.adminPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppColors.white,
                size: 24,
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
                  const SizedBox(height: 4),
                  Text(
                    course.code,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                  ),
                  if (course.scheduleDay != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.scheduleDisplay,
                          style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                        ),
                        if (course.room != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.room_rounded,
                            size: 14,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 4),
                          Text(course.room!, style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.adminPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.adminPrimary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_rounded,
                    size: 14,
                    color: AppColors.adminPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Absensi',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.adminPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
