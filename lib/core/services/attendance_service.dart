import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../models/session_model.dart';
import '../constants/supabase_constants.dart';

class AttendanceService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // ─── SESSION MANAGEMENT (Dosen) ───────────────────────────────────────────

  Future<SessionModel> createSession({
    required String courseId,
    required String lecturerId,
    required String topic,
    double? latitude,
    double? longitude,
    int radiusMeters = 100,
    int? meetingNumber,
    bool isOnline = false,
  }) async {
    final now = DateTime.now().toUtc();
    final qrToken = _uuid.v4();
    final qrExpiresAt = now.add(
      const Duration(seconds: 20),
    );

    final data = await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .insert({
          'course_id': courseId,
          'lecturer_id': lecturerId,
          'date': now.toIso8601String().split('T')[0],
          'start_time': now.toIso8601String(),
          'qr_token': qrToken,
          'qr_expires_at': qrExpiresAt.toIso8601String(),
          'latitude': latitude,
          'longitude': longitude,
          'radius_meters': radiusMeters,
          'status': 'open',
          'topic': topic,
          'meeting_number': meetingNumber,
          'is_online': isOnline,
        })
        .select()
        .single();

    return SessionModel.fromMap(data);
  }

  Future<SessionModel> refreshQrToken(String sessionId) async {
    final now = DateTime.now().toUtc();
    final qrToken = _uuid.v4();
    final qrExpiresAt = now.add(
      const Duration(seconds: 20),
    );

    final data = await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .update({
          'qr_token': qrToken,
          'qr_expires_at': qrExpiresAt.toIso8601String(),
        })
        .eq('id', sessionId)
        .select()
        .single();

    return SessionModel.fromMap(data);
  }

  Future<void> closeSession(String sessionId) async {
    // Get session details to find course_id
    final sessionData = await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .select('course_id')
        .eq('id', sessionId)
        .single();
    
    final courseId = sessionData['course_id'] as String;

    await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .update({
          'status': 'closed',
          'end_time': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId);

    // Sync Alpha for missing students
    try {
      final enrolled = await _client
          .from(SupabaseConstants.enrollmentsTable)
          .select('student_id')
          .eq('course_id', courseId);
      
      final enrolledIds = (enrolled as List).map((e) => e['student_id'] as String).toSet();

      final attended = await _client
          .from(SupabaseConstants.attendancesTable)
          .select('student_id')
          .eq('session_id', sessionId);
      
      final attendedIds = (attended as List).map((e) => e['student_id'] as String).toSet();

      final missingIds = enrolledIds.difference(attendedIds);

      if (missingIds.isNotEmpty) {
        final now = DateTime.now().toUtc().toIso8601String();
        final inserts = missingIds.map((id) => {
          'session_id': sessionId,
          'student_id': id,
          'status': AttendanceStatus.alpha.value,
          'check_in_at': now,
        }).toList();

        await _client.from(SupabaseConstants.attendancesTable).insert(inserts);
      }
    } catch (_) {}
  }

  Future<List<SessionModel>> getSessionsByCourse(String courseId) async {
    final data = await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .select()
        .eq('course_id', courseId)
        .order('date', ascending: false);

    return (data as List).map((e) => SessionModel.fromMap(e)).toList();
  }

  Future<SessionModel?> getSessionByToken(String qrToken) async {
    final data = await _client
        .from(SupabaseConstants.attendanceSessionsTable)
        .select()
        .eq('qr_token', qrToken)
        .eq('status', 'open')
        .maybeSingle();

    if (data == null) return null;
    return SessionModel.fromMap(data);
  }

  // ─── ATTENDANCE (Mahasiswa) ───────────────────────────────────────────────

  Future<AttendanceCheckInResult> checkIn({
    required String sessionId,
    required String studentId,
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    // Validate QR token
    final session = await getSessionByToken(qrToken);
    if (session == null) {
      return AttendanceCheckInResult(
        success: false,
        message: 'QR Code tidak valid atau sesi sudah ditutup',
      );
    }

    if (!session.isQrValid) {
      return AttendanceCheckInResult(
        success: false,
        message: 'QR Code sudah kadaluarsa. Minta dosen untuk refresh QR.',
      );
    }

    // Auto-enroll student into the course
    try {
      final isEnrolled = await _client
          .from(SupabaseConstants.enrollmentsTable)
          .select()
          .eq('student_id', studentId)
          .eq('course_id', session.courseId)
          .maybeSingle();

      if (isEnrolled == null) {
        await _client.from(SupabaseConstants.enrollmentsTable).insert({
          'student_id': studentId,
          'course_id': session.courseId,
        });
      }
    } catch (_) {}

    // Check if already checked in
    final existing = await _client
        .from(SupabaseConstants.attendancesTable)
        .select()
        .eq('session_id', sessionId)
        .eq('student_id', studentId)
        .maybeSingle();

    if (existing != null) {
      return AttendanceCheckInResult(
        success: false,
        message: 'Anda sudah melakukan absensi untuk sesi ini.',
        attendance: AttendanceModel.fromMap(existing),
      );
    }

    // Anti-Titip Absen: Geofencing
    if (!session.isOnline && 
        session.latitude != null && 
        session.longitude != null && 
        latitude != null && 
        longitude != null) {
      final distance = Geolocator.distanceBetween(
        session.latitude!,
        session.longitude!,
        latitude,
        longitude,
      );
      
      if (distance > session.radiusMeters) {
        return AttendanceCheckInResult(
          success: false,
          message: 'Gagal: Anda berada di luar jangkauan kelas (${distance.toStringAsFixed(0)}m / ${session.radiusMeters}m).',
        );
      }
    }

    // Determine status: hadir or terlambat
    final now = DateTime.now().toUtc();
    final graceCutoff = session.startTime.add(
      const Duration(minutes: SupabaseConstants.gracePeriodMinutes),
    );
    final status = now.isBefore(graceCutoff)
        ? AttendanceStatus.hadir
        : AttendanceStatus.terlambat;

    final data = await _client
        .from(SupabaseConstants.attendancesTable)
        .insert({
          'session_id': sessionId,
          'student_id': studentId,
          'check_in_at': now.toIso8601String(),
          'check_in_lat': latitude,
          'check_in_lng': longitude,
          'status': status.value,
        })
        .select()
        .single();

    return AttendanceCheckInResult(
      success: true,
      message: status == AttendanceStatus.hadir
          ? '✅ Berhasil hadir tepat waktu!'
          : '⚠️ Berhasil absen, namun Anda terlambat.',
      attendance: AttendanceModel.fromMap(data),
    );
  }

  Future<AttendanceModel?> checkOut({
    required String attendanceId,
  }) async {
    final data = await _client
        .from(SupabaseConstants.attendancesTable)
        .update({
          'check_out_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', attendanceId)
        .select()
        .single();

    return AttendanceModel.fromMap(data);
  }

  Future<List<AttendanceModel>> getStudentAttendances({
    required String studentId,
    String? courseId,
  }) async {
    var query = _client
        .from(SupabaseConstants.attendancesTable)
        .select('''
          *,
          attendance_sessions!inner(
            date,
            meeting_number,
            course_id,
            courses!inner(name, code)
          )
        ''')
        .eq('student_id', studentId);

    if (courseId != null) {
      query = query.eq('attendance_sessions.course_id', courseId);
    }

    final data = await query.order('check_in_at', ascending: false);

    return (data as List).map((e) {
      final session = e['attendance_sessions'] as Map<String, dynamic>;
      final course = session['courses'] as Map<String, dynamic>;
      return AttendanceModel.fromMap({
        ...e,
        'course_name': course['name'],
        'course_code': course['code'],
        'session_date': session['date'],
        'meeting_number': session['meeting_number'],
      });
    }).toList();
  }

  Future<List<AttendanceModel>> getSessionAttendances(String sessionId) async {
    final data = await _client
        .from(SupabaseConstants.attendancesTable)
        .select('''
          *,
          profiles!inner(full_name, nim_or_nip)
        ''')
        .eq('session_id', sessionId)
        .order('check_in_at');

    return (data as List).map((e) {
      final profile = e['profiles'] as Map<String, dynamic>;
      return AttendanceModel.fromMap({
        ...e,
        'student_name': profile['full_name'],
        'student_nim': profile['nim_or_nip'],
      });
    }).toList();
  }

  Future<AttendanceSummary> getStudentSummary({
    required String studentId,
    String? courseId,
  }) async {
    final attendances = await getStudentAttendances(
      studentId: studentId,
      courseId: courseId,
    );

    int hadir = 0, terlambat = 0, alpha = 0, izin = 0, sakit = 0;
    for (final a in attendances) {
      switch (a.status) {
        case AttendanceStatus.hadir:
          hadir++;
          break;
        case AttendanceStatus.terlambat:
          terlambat++;
          break;
        case AttendanceStatus.alpha:
          alpha++;
          break;
        case AttendanceStatus.izin:
          izin++;
          break;
        case AttendanceStatus.sakit:
          sakit++;
          break;
      }
    }

    // Calculate dynamic Alpha based on total sessions created for enrolled courses
    int totalSessions = attendances.length;
    try {
      var query = _client.from(SupabaseConstants.attendanceSessionsTable).select('id');
      if (courseId != null) {
        query = query.eq('course_id', courseId);
      } else {
        final enrollments = await _client
            .from(SupabaseConstants.enrollmentsTable)
            .select('course_id')
            .eq('student_id', studentId);
        final courseIds = (enrollments as List).map((e) => e['course_id']).toList();
        if (courseIds.isNotEmpty) {
          query = query.inFilter('course_id', courseIds);
        } else {
          // If no courses, there are no sessions. Avoid Postgres error for invalid UUID 'none'.
          return AttendanceSummary(
            totalSessions: 0,
            hadir: hadir,
            terlambat: terlambat,
            alpha: alpha,
            izin: izin,
            sakit: sakit,
          );
        }
      }
      final sessionsData = await query;
      final actualTotalSessions = (sessionsData as List).length;
      if (actualTotalSessions > totalSessions) {
        totalSessions = actualTotalSessions;
      }
    } catch (_) {}

    final attendedCount = hadir + terlambat + izin + sakit;
    // Add dynamically calculated alpha to any physically inserted alpha records
    final dynamicAlpha = totalSessions - attendedCount;
    if (dynamicAlpha > alpha) {
      alpha = dynamicAlpha;
    }

    return AttendanceSummary(
      totalSessions: totalSessions,
      hadir: hadir,
      terlambat: terlambat,
      alpha: alpha,
      izin: izin,
      sakit: sakit,
    );
  }

  // Real-time listener for session attendance
  RealtimeChannel listenToSessionAttendances({
    required String sessionId,
    required void Function(List<AttendanceModel>) onData,
  }) {
    return _client
        .channel('session_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.attendancesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (_) async {
            final data = await getSessionAttendances(sessionId);
            onData(data);
          },
        )
        .subscribe();
  }
  Future<void> updateAttendanceStatus({
    required String studentId,
    required String sessionId,
    required AttendanceStatus status,
  }) async {
    final existing = await _client
        .from(SupabaseConstants.attendancesTable)
        .select('id')
        .eq('student_id', studentId)
        .eq('session_id', sessionId)
        .maybeSingle();

    if (existing != null) {
      // Update existing record
      await _client
          .from(SupabaseConstants.attendancesTable)
          .update({'status': status.value})
          .eq('id', existing['id']);
    } else {
      // Insert new record (previously implicit alpha)
      await _client.from(SupabaseConstants.attendancesTable).insert({
        'student_id': studentId,
        'session_id': sessionId,
        'status': status.value,
        'check_in_at': DateTime.now().toIso8601String(),
      });
    }
  }
}

class AttendanceCheckInResult {
  final bool success;
  final String message;
  final AttendanceModel? attendance;

  const AttendanceCheckInResult({
    required this.success,
    required this.message,
    this.attendance,
  });
}
