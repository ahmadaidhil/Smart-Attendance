import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/attendance_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/attendance_card.dart';

class AttendanceDetailScreen extends StatelessWidget {
  final AttendanceModel attendance;

  const AttendanceDetailScreen({super.key, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final duration = attendance.duration;
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Detail Kehadiran', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status badge
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _statusColor(attendance.status).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _statusColor(attendance.status),
                        width: 2.5,
                      ),
                    ),
                    child: Icon(
                      _statusIcon(attendance.status),
                      color: _statusColor(attendance.status),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AttendanceStatusChip(status: attendance.status),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Info cards
            _InfoSection(
              title: 'Mata Kuliah',
              items: [
                _InfoRow(
                  icon: Icons.book_rounded,
                  label: 'Nama',
                  value: attendance.courseName ?? '-',
                ),
                _InfoRow(
                  icon: Icons.tag_rounded,
                  label: 'Kode',
                  value: attendance.courseCode ?? '-',
                ),
                if (attendance.meetingNumber != null)
                  _InfoRow(
                    icon: Icons.format_list_numbered_rounded,
                    label: 'Pertemuan Ke-',
                    value: attendance.meetingNumber.toString(),
                  ),
                if (attendance.sessionDate != null)
                  _InfoRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal Pertemuan',
                    value: DateFormatter.formatDate(attendance.sessionDate!),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            _InfoSection(
              title: 'Waktu Kehadiran',
              items: [
                _InfoRow(
                  icon: Icons.login_rounded,
                  label: 'Check-in',
                  value: DateFormatter.formatDateTime(
                    attendance.checkInAt.toLocal(),
                  ),
                  valueColor: AppColors.success,
                ),
                if (attendance.checkOutAt != null)
                  _InfoRow(
                    icon: Icons.logout_rounded,
                    label: 'Check-out',
                    value: DateFormatter.formatDateTime(
                      attendance.checkOutAt!.toLocal(),
                    ),
                    valueColor: AppColors.warning,
                  ),
                if (duration != null)
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Durasi',
                    value: DateFormatter.formatDuration(duration),
                  ),
              ],
            ),

            if (attendance.checkInLat != null &&
                attendance.checkInLng != null) ...[
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Lokasi Absensi',
                items: [
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Koordinat',
                    value:
                        '${attendance.checkInLat!.toStringAsFixed(5)}, ${attendance.checkInLng!.toStringAsFixed(5)}',
                  ),
                ],
              ),
            ],

            if (attendance.notes != null && attendance.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Catatan',
                items: [
                  _InfoRow(
                    icon: Icons.notes_rounded,
                    label: '',
                    value: attendance.notes!,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return AppColors.success;
      case AttendanceStatus.terlambat:
        return AppColors.warning;
      case AttendanceStatus.alpha:
        return AppColors.danger;
      case AttendanceStatus.izin:
        return AppColors.info;
      case AttendanceStatus.sakit:
        return AppColors.accentLight;
    }
  }

  IconData _statusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.hadir:
        return Icons.check_circle_rounded;
      case AttendanceStatus.terlambat:
        return Icons.schedule_rounded;
      case AttendanceStatus.alpha:
        return Icons.cancel_rounded;
      case AttendanceStatus.izin:
        return Icons.info_rounded;
      case AttendanceStatus.sakit:
        return Icons.medical_services_rounded;
    }
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;

  const _InfoSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
          ),
          const Divider(color: AppColors.grey200, height: 1),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: item,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 10),
        if (label.isNotEmpty) ...[
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600)),
          const Spacer(),
        ],
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: valueColor ?? AppColors.primaryDark,
              fontWeight: label.isEmpty ? null : FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
