import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final bool isPercentage;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.isPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.statNumberMd.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class AttendancePercentageCard extends StatelessWidget {
  final double percentage;
  final int totalSessions;
  final int present;

  const AttendancePercentageCard({
    super.key,
    required this.percentage,
    required this.totalSessions,
    required this.present,
  });

  Color get _color {
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  String get _statusText {
    if (percentage >= 75) return 'Kehadiran Baik 🎉';
    if (percentage >= 50) return 'Perlu Ditingkatkan ⚠️';
    return 'Kehadiran Rendah ❌';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _color.withOpacity(0.18),
            _color.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: _color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: AppTextStyles.label.copyWith(
                  color: _color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Kehadiran',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$present dari $totalSessions pertemuan',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _statusText,
                    style: AppTextStyles.labelSmall.copyWith(color: _color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
