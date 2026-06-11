import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/custom_button.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Laporan Global', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan Kehadiran', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: 8),
            Text(
              'Export laporan kehadiran seluruh mahasiswa',
              style: AppTextStyles.body.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: 28),
            _ReportCard(
              title: 'Rekap Kehadiran Per Mata Kuliah',
              subtitle: 'Laporan per MK dengan detail per mahasiswa',
              icon: Icons.book_rounded,
              color: AppColors.accent,
              onExportPdf: () {},
              onExportExcel: () {},
            ),
            _ReportCard(
              title: 'Rekap Kehadiran Per Mahasiswa',
              subtitle: 'Laporan semua MK per mahasiswa',
              icon: Icons.school_rounded,
              color: AppColors.success,
              onExportPdf: () {},
              onExportExcel: () {},
            ),
            _ReportCard(
              title: 'Laporan Mahasiswa Tidak Hadir',
              subtitle: 'Daftar mahasiswa yang sering alpha',
              icon: Icons.person_off_rounded,
              color: AppColors.danger,
              onExportPdf: () {},
              onExportExcel: () {},
            ),
            _ReportCard(
              title: 'Rekap Kehadiran Bulanan',
              subtitle: 'Rekapitulasi kehadiran per bulan',
              icon: Icons.calendar_month_rounded,
              color: AppColors.warning,
              onExportPdf: () {},
              onExportExcel: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onExportPdf;
  final VoidCallback onExportExcel;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onExportPdf,
    required this.onExportExcel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    size: 16,
                    color: AppColors.danger,
                  ),
                  label: Text(
                    'PDF',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.danger,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportExcel,
                  icon: const Icon(
                    Icons.table_chart,
                    size: 16,
                    color: AppColors.success,
                  ),
                  label: Text(
                    'Excel',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.success,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
