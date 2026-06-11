import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/course_model.dart';
import '../../core/models/attendance_model.dart';
import '../../core/models/session_model.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/course_service.dart';
import '../../core/services/export_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/providers/attendance_provider.dart';
import '../../shared/widgets/attendance_card.dart';
import '../../shared/widgets/custom_button.dart';

class CourseRecapScreen extends StatefulWidget {
  const CourseRecapScreen({super.key});

  @override
  State<CourseRecapScreen> createState() => _CourseRecapScreenState();
}

class _CourseRecapScreenState extends State<CourseRecapScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final CourseService _courseService = CourseService();
  final ExportService _exportService = ExportService();

  CourseModel? _selectedCourse;
  List<Map<String, dynamic>> _students = [];
  List<AttendanceModel> _allAttendances = [];
  List<SessionModel> _sessions = [];
  int _totalSessions = 0;
  bool _isLoading = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CourseProvider>().loadCoursesByLecturer(user.id);
      }
    });
  }

  Future<void> _loadRecap() async {
    if (_selectedCourse == null) return;
    setState(() => _isLoading = true);

    final students = await _courseService.getEnrolledStudents(
      _selectedCourse!.id,
    );
    final sessions = await _attendanceService.getSessionsByCourse(
      _selectedCourse!.id,
    );
    final allAttendances = <AttendanceModel>[];
    for (final session in sessions) {
      final atts = await _attendanceService.getSessionAttendances(session.id);
      allAttendances.addAll(atts);
    }

    final studentMap = {
      for (final s in students) s['id'] as String: s,
    };

    for (final a in allAttendances) {
      if (!studentMap.containsKey(a.studentId)) {
        studentMap[a.studentId] = {
          'id': a.studentId,
          'full_name': a.studentName ?? 'Unknown',
          'nim_or_nip': a.studentNim ?? '-',
        };
      }
    }

    final finalStudents = studentMap.values.toList();
    finalStudents.sort((a, b) => (a['full_name'] as String).compareTo(b['full_name'] as String));

    setState(() {
      _students = finalStudents;
      _allAttendances = allAttendances;
      _sessions = sessions;
      _totalSessions = sessions.length;
      _isLoading = false;
    });
  }

  Map<String, Map<String, int>> get _studentSummary {
    final map = <String, Map<String, int>>{};
    for (final s in _students) {
      map[s['id'] as String] = {
        'hadir': 0,
        'terlambat': 0,
        'alpha': 0,
        'izin': 0,
        'sakit': 0,
      };
    }
    for (final a in _allAttendances) {
      if (a.status != AttendanceStatus.alpha) {
        map[a.studentId]?[a.status.value] =
            (map[a.studentId]?[a.status.value] ?? 0) + 1;
      }
    }
    // Calculate dynamic alpha
    for (final s in _students) {
      final studentId = s['id'] as String;
      final studentMap = map[studentId]!;
      final attended = studentMap['hadir']! +
          studentMap['terlambat']! +
          studentMap['izin']! +
          studentMap['sakit']!;
      final dynamicAlpha = _totalSessions - attended;
      if (dynamicAlpha > 0) {
        studentMap['alpha'] = dynamicAlpha;
      }
    }
    return map;
  }

  void _showEditAttendanceModal(Map<String, dynamic> student) {
    final studentId = student['id'] as String;
    final studentName = student['full_name'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _EditAttendanceSheet(
          studentId: studentId,
          studentName: studentName,
          sessions: _sessions,
          allAttendances: _allAttendances,
          onStatusChanged: (sessionId, newStatus) async {
            final success = await context.read<AttendanceProvider>().updateStudentAttendanceStatus(
              studentId: studentId,
              sessionId: sessionId,
              status: newStatus,
            );
            if (success) {
              if (mounted) {
                _loadRecap();
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<CourseProvider>();

    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Rekap Kehadiran', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
        actions: [
          if (_selectedCourse != null && _students.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (v) async {
                setState(() => _isExporting = true);
                if (v == 'pdf') {
                  await _exportService.exportToPdf(
                    course: _selectedCourse!,
                    students: _students,
                    attendances: _allAttendances,
                    totalSessions: _totalSessions,
                  );
                } else {
                  await _exportService.exportToExcel(
                    course: _selectedCourse!,
                    students: _students,
                    attendances: _allAttendances,
                    totalSessions: _totalSessions,
                  );
                }
                setState(() => _isExporting = false);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Text('Export PDF', style: AppTextStyles.body.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text('Export Excel', style: AppTextStyles.body.copyWith(color: AppColors.primaryDark)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Course Selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<CourseModel>(
                    value: _selectedCourse,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.grey200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.grey200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      hint: Text(
                        'Pilih mata kuliah',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                    dropdownColor: AppColors.white,
                    style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
                    items: courses.courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.code} - ${c.nameWithClass}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (c) {
                      setState(() => _selectedCourse = c);
                      _loadRecap();
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _selectedCourse == null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              size: 64,
                              color: AppColors.grey700,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Pilih mata kuliah untuk melihat rekap',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildRecap(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecap() {
    final summary = _studentSummary;
    final totalHadir = _allAttendances
        .where((a) => a.status == AttendanceStatus.hadir)
        .length;
    final totalTerlambat = _allAttendances
        .where((a) => a.status == AttendanceStatus.terlambat)
        .length;
        
    int totalAlpha = 0;
    for (final s in _students) {
      final sid = s['id'] as String;
      final sum = summary[sid] ?? {};
      final h = sum['hadir'] ?? 0;
      final t = sum['terlambat'] ?? 0;
      final explicitA = sum['alpha'] ?? 0;
      final i = sum['izin'] ?? 0;
      final sakit = sum['sakit'] ?? 0;
      
      final attended = h + t + explicitA + i + sakit;
      final implicitA = _totalSessions > attended ? _totalSessions - attended : 0;
      totalAlpha += explicitA + implicitA;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        // Summary Cards
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
              Text('Ringkasan', style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _RecapStat(
                    label: 'Pertemuan',
                    value: _totalSessions.toString(),
                    color: AppColors.accent,
                  ),
                  _RecapStat(
                    label: 'Mahasiswa',
                    value: _students.length.toString(),
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _RecapStat(
                    label: 'Hadir',
                    value: totalHadir.toString(),
                    color: AppColors.success,
                  ),
                  _RecapStat(
                    label: 'Terlambat',
                    value: totalTerlambat.toString(),
                    color: AppColors.warning,
                  ),
                  _RecapStat(
                    label: 'Alpha',
                    value: totalAlpha.toString(),
                    color: AppColors.danger,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text('Daftar Kehadiran Mahasiswa', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 12),

        // Student rows
        ..._students.map((s) {
          final sid = s['id'] as String;
          final sum = summary[sid] ?? {};
          final h = sum['hadir'] ?? 0;
          final t = sum['terlambat'] ?? 0;
          final explicitA = sum['alpha'] ?? 0;
          final i = sum['izin'] ?? 0;
          final sakit = sum['sakit'] ?? 0;
          
          final attended = h + t + explicitA + i + sakit;
          final implicitA = _totalSessions > attended ? _totalSessions - attended : 0;
          final a = explicitA + implicitA;
          
          final pct = _totalSessions > 0
              ? ((h + t) / _totalSessions * 100)
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Material(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showEditAttendanceModal(s),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.accent.withOpacity(0.15),
                      child: Text(
                        (s['full_name'] as String).substring(0, 1),
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['full_name'] as String,
                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            s['nim_or_nip'] as String? ?? '-',
                            style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: AppTextStyles.h4.copyWith(
                            color: pct >= 75
                                ? AppColors.success
                                : pct >= 50
                                    ? AppColors.warning
                                    : AppColors.danger,
                          ),
                        ),
                        Text('kehadiran', style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _AttStat('H', h.toString(), AppColors.success),
                    const SizedBox(width: 8),
                    _AttStat('T', t.toString(), AppColors.warning),
                    const SizedBox(width: 8),
                    _AttStat('A', a.toString(), AppColors.danger),
                    const SizedBox(width: 8),
                    _AttStat(
                      'I',
                      (sum['izin'] ?? 0).toString(),
                      AppColors.info,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _totalSessions > 0
                              ? (h + t) / _totalSessions
                              : 0,
                          backgroundColor: AppColors.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 75
                                ? AppColors.success
                                : pct >= 50
                                    ? AppColors.warning
                                    : AppColors.danger,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
        }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RecapStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RecapStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _EditAttendanceSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final List<SessionModel> sessions;
  final List<AttendanceModel> allAttendances;
  final Future<void> Function(String sessionId, AttendanceStatus status) onStatusChanged;

  const _EditAttendanceSheet({
    required this.studentId,
    required this.studentName,
    required this.sessions,
    required this.allAttendances,
    required this.onStatusChanged,
  });

  @override
  State<_EditAttendanceSheet> createState() => _EditAttendanceSheetState();
}

class _EditAttendanceSheetState extends State<_EditAttendanceSheet> {
  bool _isSaving = false;
  final Map<String, AttendanceStatus> _localStatusOverrides = {};

  AttendanceStatus _getStatusForSession(String sessionId) {
    if (_localStatusOverrides.containsKey(sessionId)) {
      return _localStatusOverrides[sessionId]!;
    }
    final att = widget.allAttendances.where((a) => a.studentId == widget.studentId && a.sessionId == sessionId).toList();
    if (att.isNotEmpty) {
      return att.first.status;
    }
    return AttendanceStatus.alpha;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ubah Status Kehadiran', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
          Text(widget.studentName, style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
          const SizedBox(height: 16),
          const Divider(),
          if (widget.sessions.isEmpty)
            Expanded(child: Center(child: Text('Belum ada sesi pertemuan', style: AppTextStyles.body.copyWith(color: AppColors.grey600))))
          else
            Expanded(
              child: ListView.separated(
                itemCount: widget.sessions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final session = widget.sessions[index];
                  final status = _getStatusForSession(session.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Pertemuan ${session.meetingNumber}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    subtitle: Text(DateFormatter.formatDate(session.date), style: AppTextStyles.caption.copyWith(color: AppColors.grey600)),
                    trailing: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)) 
                      : DropdownButton<AttendanceStatus>(
                          value: status,
                          dropdownColor: AppColors.white,
                          underline: const SizedBox(),
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryDark),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.grey600),
                          items: AttendanceStatus.values.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.displayName),
                          )).toList(),
                          onChanged: (newStatus) async {
                            if (newStatus != null && newStatus != status) {
                              setState(() => _isSaving = true);
                              await widget.onStatusChanged(session.id, newStatus);
                              if (mounted) {
                                final error = context.read<AttendanceProvider>().error;
                                if (error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal: $error')),
                                  );
                                  context.read<AttendanceProvider>().clearError();
                                } else {
                                  _localStatusOverrides[session.id] = newStatus;
                                }
                                setState(() => _isSaving = false);
                              }
                            }
                          },
                        ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
