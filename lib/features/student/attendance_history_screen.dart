import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/attendance_model.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/attendance_provider.dart';
import '../../shared/widgets/attendance_card.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  AttendanceStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await context.read<AttendanceProvider>().loadStudentAttendances(
          studentId: user.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceProvider>();
    final all = attendance.attendances;
    final filtered = _filterStatus == null
        ? all
        : all.where((a) => a.status == _filterStatus).toList();

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Riwayat Kehadiran', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Semua',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                  color: AppColors.accent,
                ),
                ...AttendanceStatus.values.map(
                  (s) => _FilterChip(
                    label: s.displayName,
                    selected: _filterStatus == s,
                    onTap: () => setState(() => _filterStatus = s),
                    color: _statusColor(s),
                  ),
                ),
              ],
            ),
          ),
          // Summary bar
          if (attendance.summary != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    value: attendance.summary!.hadir.toString(),
                    label: 'Hadir',
                    color: AppColors.success,
                  ),
                  _SummaryItem(
                    value: attendance.summary!.terlambat.toString(),
                    label: 'Terlambat',
                    color: AppColors.warning,
                  ),
                  _SummaryItem(
                    value: attendance.summary!.alpha.toString(),
                    label: 'Alpha',
                    color: AppColors.danger,
                  ),
                  _SummaryItem(
                    value:
                        '${attendance.summary!.attendancePercentage.toStringAsFixed(0)}%',
                    label: 'Kehadiran',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: attendance.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.event_busy_outlined,
                              size: 64,
                              color: AppColors.grey700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data absensi',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => AttendanceCard(
                            attendance: filtered[i],
                            onTap: () => context.push(
                              '/student/attendance-detail',
                              extra: filtered[i],
                            ),
                          ),
                        ),
                      ),
          ),
        ],
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? color : AppColors.grey200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            color: selected ? color : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: color),
        ),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
      ],
    );
  }
}
