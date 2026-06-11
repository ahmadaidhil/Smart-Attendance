import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/course_model.dart';
import '../../core/models/session_model.dart';
import '../../core/models/attendance_model.dart';
import '../../core/services/attendance_service.dart';
import '../../core/services/location_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/attendance_provider.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/widgets/attendance_card.dart';
import '../../shared/widgets/custom_button.dart';

class GenerateQrScreen extends StatefulWidget {
  final CourseModel? course;
  const GenerateQrScreen({super.key, this.course});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  final LocationService _locationService = LocationService();
  final AttendanceService _attendanceService = AttendanceService();

  CourseModel? _selectedCourse;
  int? _selectedMeetingNumber;
  SessionModel? _activeSession;
  List<AttendanceModel> _liveAttendances = [];
  Timer? _qrRefreshTimer;
  Timer? _countdownTimer;
  int _secondsLeft = 0;
  bool _isCreating = false;
  bool _isClosing = false;
  bool _isOnlineClass = false;
  RealtimeChannel? _realtimeChannel;
  final _topicCtrl = TextEditingController();

  List<int> _usedMeetingNumbers = [];

  @override
  void initState() {
    super.initState();
    _selectedCourse = widget.course;
    if (_selectedCourse != null) {
      _fetchUsedMeetingNumbers(_selectedCourse!.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CourseProvider>().loadCoursesByLecturer(user.id);
      }
    });
  }

  Future<void> _fetchUsedMeetingNumbers(String courseId) async {
    try {
      final sessions = await _attendanceService.getSessionsByCourse(courseId);
      final nullSessions = sessions.where((s) => s.meetingNumber == null).toList();
      
      final used = sessions.map((s) => s.meetingNumber).whereType<int>().toList();
      
      // Auto-fix any sessions that were created without a meeting number
      if (nullSessions.isNotEmpty) {
        final supabase = Supabase.instance.client;
        int nextNum = 1;
        for (final s in nullSessions) {
          while (used.contains(nextNum)) {
            nextNum++;
          }
          await supabase.from('attendance_sessions').update({'meeting_number': nextNum}).eq('id', s.id);
          used.add(nextNum);
        }
      }

      if (mounted) {
        setState(() {
          _usedMeetingNumbers = used;
          
          // Auto-select the next available meeting number
          int autoNext = 1;
          while (_usedMeetingNumbers.contains(autoNext)) {
            autoNext++;
          }
          if (autoNext <= 16) {
            _selectedMeetingNumber = autoNext;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching used meeting numbers: $e');
    }
  }

  @override
  void dispose() {
    _qrRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final user = context.read<AuthProvider>().user!;
    final position = await _locationService.getCurrentPosition();

    final session = await context.read<AttendanceProvider>().createSession(
          courseId: _selectedCourse!.id,
          lecturerId: user.id,
          topic: _topicCtrl.text.trim().isEmpty
              ? 'Pertemuan ${DateTime.now().day}/${DateTime.now().month}'
              : _topicCtrl.text.trim(),
          latitude: position?.latitude,
          longitude: position?.longitude,
          meetingNumber: _selectedMeetingNumber,
          isOnline: _isOnlineClass,
        );

    setState(() {
      _activeSession = session;
      _isCreating = false;
    });

    _startQrRefreshTimer();
    _listenToAttendances(session.id);
  }

  void _startQrRefreshTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });

    _qrRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshQr();
    });
  }

  void _updateCountdown() {
    if (_activeSession == null) return;
    final remaining = _activeSession!.qrExpiresAt.difference(DateTime.now());
    setState(() {
      _secondsLeft = remaining.inSeconds.clamp(0, 900);
    });
    if (_secondsLeft <= 0) {
      _refreshQr();
    }
  }

  Future<void> _refreshQr() async {
    if (_activeSession == null) return;
    await context.read<AttendanceProvider>().refreshQrToken(_activeSession!.id);
    setState(() {
      _activeSession = context.read<AttendanceProvider>().activeSession;
    });
    _updateCountdown();
  }

  void _listenToAttendances(String sessionId) async {
    // Fetch current existing attendances first
    final existing = await _attendanceService.getSessionAttendances(sessionId);
    if (mounted) {
      setState(() => _liveAttendances = existing);
    }

    _realtimeChannel = _attendanceService.listenToSessionAttendances(
      sessionId: sessionId,
      onData: (list) {
        if (mounted) setState(() => _liveAttendances = list);
      },
    );
  }

  Future<void> _closeSession() async {
    if (_activeSession == null) return;
    setState(() => _isClosing = true);
    _qrRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    await context.read<AttendanceProvider>().closeSession(_activeSession!.id);
    setState(() {
      _activeSession = null;
      _liveAttendances = [];
      _isClosing = false;
    });
  }

  String get _qrData {
    if (_activeSession == null) return '';
    return '${_activeSession!.id}:${_activeSession!.qrToken}';
  }

  String get _countdownText {
    final mins = _secondsLeft ~/ 60;
    final secs = _secondsLeft % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
          onPressed: () {
            if (_activeSession != null) {
              _showCloseConfirmation();
            } else {
              context.pop();
            }
          },
        ),
        title: Text('Sesi Absensi', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
        actions: [
          if (_activeSession != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).then().fadeOut(duration: 600.ms),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _activeSession == null
          ? _buildSetup(courses)
          : _buildActiveSession(),
    );
  }

  Widget _buildSetup(CourseProvider courses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pilih Mata Kuliah', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 14),
          DropdownButtonFormField<CourseModel>(
            value: _selectedCourse,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hint: Text(
                'Pilih mata kuliah',
                style: AppTextStyles.body.copyWith(color: AppColors.grey600),
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
              if (c != null) _fetchUsedMeetingNumbers(c.id);
            },
          ),
          const SizedBox(height: 20),
          Text('Pertemuan Ke- (Opsional)', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedMeetingNumber,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hint: Text(
                'Pilih pertemuan',
                style: AppTextStyles.body.copyWith(color: AppColors.grey600),
              ),
            ),
            dropdownColor: AppColors.white,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
            items: List.generate(
              16,
              (index) {
                final meetingNum = index + 1;
                final isUsed = _usedMeetingNumbers.contains(meetingNum);
                return DropdownMenuItem(
                  value: meetingNum,
                  enabled: !isUsed,
                  child: Text(
                    isUsed 
                        ? 'Pertemuan Ke-$meetingNum ✓ (Selesai)' 
                        : 'Pertemuan Ke-$meetingNum',
                    style: TextStyle(
                      color: isUsed ? AppColors.success : AppColors.primaryDark,
                      decoration: isUsed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              },
            ),
            onChanged: (val) => setState(() => _selectedMeetingNumber = val),
          ),
          const SizedBox(height: 20),
          Text('Topik Pertemuan (Opsional)', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _topicCtrl,
            style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
            decoration: InputDecoration(
              hintText: 'Contoh: Materi Bab 3 - Sorting Algorithm',
              hintStyle: AppTextStyles.body.copyWith(color: AppColors.grey600),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.grey200),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: _isOnlineClass,
            onChanged: (val) => setState(() => _isOnlineClass = val),
            title: Text(
              'Mode Kuliah Online',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Abaikan jarak GPS & berikan Dynamic QR cepat.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.grey500,
              ),
            ),
            activeTrackColor: AppColors.success,
            activeColor: Colors.white,
            inactiveTrackColor: AppColors.danger,
            inactiveThumbColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            tileColor: Colors.transparent,
          ),
          const SizedBox(height: 32),
          CustomButton(
            label: 'Buka Sesi & Generate QR',
            onPressed: _isCreating ? null : _createSession,
            isLoading: _isCreating,
            icon: const Icon(
              Icons.qr_code_2_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSession() {
    final session = _activeSession!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // QR Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _selectedCourse?.name ?? '',
                  style: AppTextStyles.h4.copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  session.topic ?? '',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A1628),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A1628),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
                // Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _secondsLeft < 60
                          ? AppColors.danger
                          : AppColors.grey600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Refresh dalam $_countdownText',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _secondsLeft < 60
                            ? AppColors.danger
                            : AppColors.grey600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _refreshQr,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Refresh',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live attendance list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mahasiswa Hadir', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '${_liveAttendances.length} hadir',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._liveAttendances.map(
                  (a) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent.withOpacity(0.2),
                          child: Text(
                            (a.studentName ?? 'U').substring(0, 1),
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
                                a.studentName ?? '-',
                                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                              ),
                              Text(
                                a.studentNim ?? '',
                                style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AttendanceStatusChip(
                              status: a.status,
                              small: true,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatTime(a.checkInAt.toLocal()),
                              style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Tutup Sesi',
                  onPressed: _showCloseConfirmation,
                  isLoading: _isClosing,
                  gradient: AppColors.dangerGradient,
                  icon: const Icon(
                    Icons.stop_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tutup Sesi?', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
        content: Text(
          'Sesi absensi akan ditutup dan mahasiswa tidak bisa lagi melakukan absensi.',
          style: AppTextStyles.body.copyWith(color: AppColors.grey600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: AppTextStyles.body.copyWith(color: AppColors.grey600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _closeSession().then((_) {
                if (mounted) context.pop();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tutup Sesi'),
          ),
        ],
      ),
    );
  }
}
