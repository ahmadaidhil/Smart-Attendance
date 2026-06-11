import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isAdmin = user?.role == UserRole.admin;

    return Drawer(
      backgroundColor: isAdmin ? AppColors.adminPrimaryDark : AppColors.primaryMid,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isAdmin ? AppColors.adminGradient : AppColors.primaryGradient,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.initials ?? 'U',
                            style: AppTextStyles.h3,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '-',
                          style: AppTextStyles.h4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.nimOrNip ?? '',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            user?.role.displayName ?? '',
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Menu items based on role
            if (user?.isMahasiswa ?? false) ...[
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: () => context.go('/student'),
              ),
              _DrawerItem(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR Absensi',
                onTap: () => context.push('/student/scan'),
              ),
              _DrawerItem(
                icon: Icons.history_rounded,
                label: 'Riwayat Kehadiran',
                onTap: () => context.push('/student/history'),
              ),
            ],
            if (user?.isDosen ?? false) ...[
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                onTap: () => context.go('/lecturer'),
              ),
              _DrawerItem(
                icon: Icons.qr_code_2_rounded,
                label: 'Generate QR',
                onTap: () => context.push('/lecturer/generate-qr'),
              ),
              _DrawerItem(
                icon: Icons.bar_chart_rounded,
                label: 'Rekap Kehadiran',
                onTap: () => context.push('/lecturer/recap'),
              ),
            ],
            if (user?.isAdmin ?? false) ...[
              _DrawerItem(
                icon: Icons.admin_panel_settings_rounded,
                label: 'Admin Dashboard',
                onTap: () => context.go('/admin'),
              ),
              _DrawerItem(
                icon: Icons.people_rounded,
                label: 'Manajemen User',
                onTap: () => context.push('/admin/users'),
              ),
              _DrawerItem(
                icon: Icons.book_rounded,
                label: 'Manajemen MK',
                onTap: () => context.push('/admin/courses'),
              ),
              _DrawerItem(
                icon: Icons.assessment_rounded,
                label: 'Laporan',
                onTap: () => context.push('/admin/reports'),
              ),
            ],
            const Divider(color: AppColors.glassBorder, height: 24),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Pengaturan',
              onTap: () {
                Navigator.pop(context); // Close drawer first
                if (user?.isAdmin ?? false) {
                  context.push('/admin/settings');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pengaturan profil akan segera hadir.')),
                  );
                }
              },
            ),
            const Spacer(),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Keluar',
              color: AppColors.danger,
              onTap: () async {
                Navigator.pop(context);
                await context.read<AuthProvider>().signOut();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ?? AppColors.grey200,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color ?? AppColors.grey200,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
