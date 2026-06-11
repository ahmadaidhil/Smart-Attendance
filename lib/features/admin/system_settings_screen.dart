import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  bool _emailNotification = true;
  bool _strictLocation = false;
  double _toleranceMinutes = 15;

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
        title: Text('Pengaturan Sistem', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.adminPrimary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.adminPrimary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Halaman ini merupakan simulasi untuk konfigurasi masa mendatang. Perubahan di sini belum disimpan secara permanen ke database.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.adminPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text('Konfigurasi Absensi', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Notifikasi Email',
              subtitle: 'Kirim notifikasi setiap sesi absensi dimulai',
              value: _emailNotification,
              onChanged: (val) => setState(() => _emailNotification = val),
            ),
            const Divider(color: AppColors.grey200, height: 1),
            _buildSwitchTile(
              title: 'Wajib Verifikasi Lokasi',
              subtitle: 'Tolak mahasiswa yang memindai QR dari luar kelas',
              value: _strictLocation,
              onChanged: (val) => setState(() => _strictLocation = val),
            ),
            const SizedBox(height: 30),
            Text('Toleransi Keterlambatan', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
            const SizedBox(height: 16),
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Batas Waktu Toleransi', style: AppTextStyles.body.copyWith(color: AppColors.primaryDark)),
                      Text('${_toleranceMinutes.toInt()} Menit', style: AppTextStyles.h3.copyWith(color: AppColors.adminPrimary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: _toleranceMinutes,
                    min: 0,
                    max: 60,
                    divisions: 12,
                    activeColor: AppColors.adminPrimary,
                    onChanged: (val) => setState(() => _toleranceMinutes = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Konfigurasi simulasi berhasil disimpan!')),
                  );
                },
                child: Text('Simpan Pengaturan', style: AppTextStyles.label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.adminPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
