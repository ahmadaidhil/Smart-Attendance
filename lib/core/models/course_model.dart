class CourseModel {
  final String id;
  final String code;
  final String name;
  final String? classGroup;
  final String lecturerId;
  final String? lecturerName;
  final String? lecturer2Id;
  final String? lecturer2Name;
  final String? scheduleDay;
  final String? scheduleTime;
  final String? room;
  final String? semester;
  final int? creditHours;
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    this.classGroup,
    required this.lecturerId,
    this.lecturerName,
    this.lecturer2Id,
    this.lecturer2Name,
    this.scheduleDay,
    this.scheduleTime,
    this.room,
    this.semester,
    this.creditHours,
    required this.createdAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      classGroup: map['class_group'] as String?,
      lecturerId: map['lecturer_id'] as String,
      lecturerName: map['lecturer_name'] as String?,
      lecturer2Id: map['lecturer2_id'] as String?,
      lecturer2Name: map['lecturer2_name'] as String?,
      scheduleDay: map['schedule_day'] as String?,
      scheduleTime: map['schedule_time'] as String?,
      room: map['room'] as String?,
      semester: map['semester'] as String?,
      creditHours: map['credit_hours'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'class_group': classGroup,
      'lecturer_id': lecturerId,
      'lecturer2_id': lecturer2Id,
      'schedule_day': scheduleDay,
      'schedule_time': scheduleTime,
      'room': room,
      'semester': semester,
      'credit_hours': creditHours,
    };
  }

  String get scheduleDisplay {
    if (scheduleDay != null && scheduleTime != null) {
      return '$scheduleDay, $scheduleTime';
    }
    return scheduleDay ?? scheduleTime ?? '-';
  }

  String get nameWithClass {
    if (classGroup != null && classGroup!.isNotEmpty) {
      return '$name (Kelas $classGroup)';
    }
    return name;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
