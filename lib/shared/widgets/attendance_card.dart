import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/attendance_model.dart';
import '../../core/utils/date_formatter.dart';

class AttendanceStatusChip extends StatelessWidget {
  final AttendanceStatus status;
  final bool small;

  const AttendanceStatusChip({
    super.key,
    required this.status,
    this.small = false,
  });

  Color get _color {
    switch (status) {
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

  IconData get _icon {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: small ? 11 : 13, color: _color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: AppTextStyles.labelSmall.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}

class AttendanceCard extends StatelessWidget {
  final AttendanceModel attendance;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.onTap,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 52,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.adminLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.adminPrimary.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    attendance.checkInAt.toLocal().day.toString(),
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.adminPrimary,
                      height: 1,
                    ),
                  ),
                  Text(
                    DateFormatter.formatDateShort(
                      attendance.checkInAt.toLocal(),
                    ).split(' ')[1],
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attendance.courseName ?? 'Mata Kuliah',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (attendance.meetingNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.adminPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Pertemuan ${attendance.meetingNumber}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.adminPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 13,
                        color: AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatTime(
                          attendance.checkInAt.toLocal(),
                        ),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                      ),
                      if (attendance.checkOutAt != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.logout_rounded,
                          size: 13,
                          color: AppColors.grey500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatTime(
                            attendance.checkOutAt!.toLocal(),
                          ),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                        ),
                      ],
                    ],
                  ),
                  if (attendance.courseCode != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      attendance.courseCode!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.grey500),
                    ),
                  ],
                ],
              ),
            ),
            AttendanceStatusChip(status: attendance.status),
          ],
        ),
      ),
    );
  }
}
