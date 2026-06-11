class SessionModel {
  final String id;
  final String courseId;
  final String? courseName;
  final String? courseCode;
  final String lecturerId;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final String qrToken;
  final DateTime qrExpiresAt;
  final double? latitude;
  final double? longitude;
  final int radiusMeters;
  final SessionStatus status;
  final String? topic;
  final int? meetingNumber;
  final bool isOnline;

  const SessionModel({
    required this.id,
    required this.courseId,
    this.courseName,
    this.courseCode,
    required this.lecturerId,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.qrToken,
    required this.qrExpiresAt,
    this.latitude,
    this.longitude,
    this.radiusMeters = 100,
    required this.status,
    this.topic,
    this.meetingNumber,
    this.isOnline = false,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      courseName: map['course_name'] as String?,
      courseCode: map['course_code'] as String?,
      lecturerId: map['lecturer_id'] as String,
      date: DateTime.parse(map['date'] as String),
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      qrToken: map['qr_token'] as String,
      qrExpiresAt: DateTime.parse(map['qr_expires_at'] as String),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      radiusMeters: map['radius_meters'] as int? ?? 100,
      status: SessionStatus.fromString(map['status'] as String),
      topic: map['topic'] as String?,
      meetingNumber: map['meeting_number'] as int?,
      isOnline: map['is_online'] as bool? ?? false,
    );
  }

  bool get isQrValid => DateTime.now().isBefore(qrExpiresAt);
  bool get isOpen => status == SessionStatus.open;
  bool get hasLocation => latitude != null && longitude != null;
}

enum SessionStatus {
  open('open'),
  closed('closed');

  final String value;
  const SessionStatus(this.value);

  static SessionStatus fromString(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SessionStatus.closed,
    );
  }
}
