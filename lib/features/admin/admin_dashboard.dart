import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/widgets/stat_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalMahasiswa = 0;
  int _totalDosen = 0;
  int _totalSesi = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<CourseProvider>().loadAllCourses();
    
    try {
      final supabase = Supabase.instance.client;
      final profiles = await supabase.from('profiles').select('role');
      int mahasiswa = 0;
      int dosen = 0;
      for (var p in profiles) {
        if (p['role'] == 'mahasiswa') mahasiswa++;
        if (p['role'] == 'dosen') dosen++;
      }
      
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final sessions = await supabase
          .from('attendance_sessions')
          .select('id')
          .eq('date', todayString);
          
      if (mounted) {
        setState(() {
          _totalMahasiswa = mahasiswa;
          _totalDosen = dosen;
          _totalSesi = sessions.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final courses = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
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
                      colors: [AppColors.adminPrimary, Color(0xFF600000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.adminLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: AppColors.adminPrimary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Panel', style: AppTextStyles.h2),
                                Text(
                                  user?.firstName ?? '',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
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
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.05,
                    children: [
                      _AdminStatCard(
                        value: courses.courses.length.toString(),
                        label: 'Mata Kuliah',
                        color: AppColors.adminPrimary,
                        icon: Icons.book_rounded,
                      ),
                      _AdminStatCard(
                        value: _isLoadingStats ? '-' : _totalMahasiswa.toString(),
                        label: 'Total Mahasiswa',
                        color: AppColors.adminPrimary,
                        icon: Icons.school_rounded,
                      ),
                      _AdminStatCard(
                        value: _isLoadingStats ? '-' : _totalDosen.toString(),
                        label: 'Total Dosen',
                        color: AppColors.adminPrimary,
                        icon: Icons.person_rounded,
                      ),
                      _AdminStatCard(
                        value: _isLoadingStats ? '-' : _totalSesi.toString(),
                        label: 'Sesi Hari Ini',
                        color: AppColors.adminPrimary,
                        icon: Icons.today_rounded,
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 28),
                  Text('Menu Admin', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                  const SizedBox(height: 14),

                  _AdminMenuCard(
                    icon: Icons.people_rounded,
                    title: 'Manajemen User',
                    subtitle: 'Kelola mahasiswa dan dosen',
                    color: AppColors.adminPrimary,
                    onTap: () => context.push('/admin/users'),
                  ).animate().fadeIn(delay: 150.ms),

                  _AdminMenuCard(
                    icon: Icons.book_rounded,
                    title: 'Manajemen Mata Kuliah',
                    subtitle: 'Tambah, edit, hapus mata kuliah',
                    color: AppColors.adminPrimary,
                    onTap: () => context.push('/admin/courses'),
                  ).animate().fadeIn(delay: 200.ms),

                  _AdminMenuCard(
                    icon: Icons.assessment_rounded,
                    title: 'Laporan Global',
                    subtitle: 'Rekap kehadiran seluruh mahasiswa',
                    color: AppColors.adminPrimary,
                    onTap: () => context.push('/admin/reports'),
                  ).animate().fadeIn(delay: 250.ms),

                  _AdminMenuCard(
                    icon: Icons.settings_rounded,
                    title: 'Pengaturan Sistem',
                    subtitle: 'Konfigurasi aplikasi',
                    color: AppColors.adminPrimary,
                    onTap: () => context.push('/admin/settings'),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.adminLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.adminPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
                  Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500)),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.grey400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _AdminStatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.adminLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.adminPrimary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.statNumberMd.copyWith(color: AppColors.adminPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey500),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
