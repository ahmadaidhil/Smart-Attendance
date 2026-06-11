class AttendanceModel {
  final String id;
  final String sessionId;
  final String studentId;
  final String? studentName;
  final String? studentNim;
  final String? courseName;
  final String? courseCode;
  final DateTime? sessionDate;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final double? checkInLat;
  final double? checkInLng;
  final AttendanceStatus status;
  final String? notes;
  final int? meetingNumber;

  const AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    this.studentName,
    this.studentNim,
    this.courseName,
    this.courseCode,
    this.sessionDate,
    required this.checkInAt,
    this.checkOutAt,
    this.checkInLat,
    this.checkInLng,
    required this.status,
    this.notes,
    this.meetingNumber,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      studentId: map['student_id'] as String,
      studentName: map['student_name'] as String?,
      studentNim: map['student_nim'] as String?,
      courseName: map['course_name'] as String?,
      courseCode: map['course_code'] as String?,
      sessionDate: map['session_date'] != null
          ? DateTime.parse(map['session_date'] as String)
          : null,
      checkInAt: DateTime.parse(map['check_in_at'] as String),
      checkOutAt: map['check_out_at'] != null
          ? DateTime.parse(map['check_out_at'] as String)
          : null,
      checkInLat: (map['check_in_lat'] as num?)?.toDouble(),
      checkInLng: (map['check_in_lng'] as num?)?.toDouble(),
      status: AttendanceStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      meetingNumber: map['meeting_number'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'student_id': studentId,
      'check_in_at': checkInAt.toIso8601String(),
      'check_out_at': checkOutAt?.toIso8601String(),
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'status': status.value,
      'notes': notes,
    };
  }

  Duration? get duration {
    if (checkOutAt == null) return null;
    return checkOutAt!.difference(checkInAt);
  }

  bool get hasCheckedOut => checkOutAt != null;
}

enum AttendanceStatus {
  hadir('hadir'),
  terlambat('terlambat'),
  alpha('alpha'),
  izin('izin'),
  sakit('sakit');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AttendanceStatus.alpha,
    );
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.hadir:
        return 'Hadir';
      case AttendanceStatus.terlambat:
        return 'Terlambat';
      case AttendanceStatus.alpha:
        return 'Alpha';
      case AttendanceStatus.izin:
        return 'Izin';
      case AttendanceStatus.sakit:
        return 'Sakit';
    }
  }
}

class AttendanceSummary {
  final int totalSessions;
  final int hadir;
  final int terlambat;
  final int alpha;
  final int izin;
  final int sakit;

  const AttendanceSummary({
    required this.totalSessions,
    required this.hadir,
    required this.terlambat,
    required this.alpha,
    required this.izin,
    required this.sakit,
  });

  double get attendancePercentage {
    if (totalSessions == 0) return 0;
    return ((hadir + terlambat) / totalSessions) * 100;
  }

  int get totalPresent => hadir + terlambat;
}
