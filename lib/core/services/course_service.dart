import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course_model.dart';
import '../constants/supabase_constants.dart';

class CourseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<CourseModel>> getCoursesByLecturer(String lecturerId) async {
    final data = await _client
        .from(SupabaseConstants.coursesTable)
        .select()
        .or('lecturer_id.eq.$lecturerId,lecturer2_id.eq.$lecturerId')
        .order('name');

    // Fetch lecturer names
    final profilesData = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, full_name')
        .inFilter('role', ['dosen', 'admin']);
    final profilesMap = {for (var p in profilesData) p['id']: p['full_name']};

    return (data as List).map((e) => CourseModel.fromMap({
      ...e,
      'lecturer_name': profilesMap[e['lecturer_id']],
      'lecturer2_name': profilesMap[e['lecturer2_id']],
    })).toList();
  }

  Future<List<CourseModel>> getCoursesByStudent(String studentId) async {
    final data = await _client
        .from(SupabaseConstants.enrollmentsTable)
        .select('''
          courses!inner(*)
        ''')
        .eq('student_id', studentId);

    // Fetch lecturer names
    final profilesData = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, full_name')
        .inFilter('role', ['dosen', 'admin']);
    final profilesMap = {for (var p in profilesData) p['id']: p['full_name']};

    return (data as List).map((e) {
      final course = e['courses'] as Map<String, dynamic>;
      return CourseModel.fromMap({
        ...course,
        'lecturer_name': profilesMap[course['lecturer_id']],
        'lecturer2_name': profilesMap[course['lecturer2_id']],
      });
    }).toList();
  }

  Future<List<CourseModel>> getAllCourses() async {
    final data = await _client
        .from(SupabaseConstants.coursesTable)
        .select()
        .order('name');

    // Fetch lecturer names
    final profilesData = await _client
        .from(SupabaseConstants.profilesTable)
        .select('id, full_name')
        .inFilter('role', ['dosen', 'admin']);
    final profilesMap = {for (var p in profilesData) p['id']: p['full_name']};

    return (data as List).map((e) {
      return CourseModel.fromMap({
        ...e,
        'lecturer_name': profilesMap[e['lecturer_id']],
        'lecturer2_name': profilesMap[e['lecturer2_id']],
      });
    }).toList();
  }

  Future<CourseModel> createCourse({
    required String code,
    required String name,
    String? classGroup,
    required String lecturerId,
    String? lecturer2Id,
    String? scheduleDay,
    String? scheduleTime,
    String? room,
    String? semester,
    int? creditHours,
  }) async {
    final data = await _client
        .from(SupabaseConstants.coursesTable)
        .insert({
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
        })
        .select()
        .single();

    return CourseModel.fromMap(data);
  }

  Future<void> updateCourse({
    required String courseId,
    String? code,
    String? name,
    String? classGroup,
    String? lecturerId,
    String? lecturer2Id,
    String? scheduleDay,
    String? scheduleTime,
    String? room,
    String? semester,
    bool clearLecturer2 = false,
  }) async {
    final updates = <String, dynamic>{};
    if (code != null) updates['code'] = code;
    if (name != null) updates['name'] = name;
    if (classGroup != null) updates['class_group'] = classGroup;
    if (lecturerId != null) updates['lecturer_id'] = lecturerId;
    if (lecturer2Id != null) updates['lecturer2_id'] = lecturer2Id;
    if (scheduleDay != null) updates['schedule_day'] = scheduleDay;
    if (scheduleTime != null) updates['schedule_time'] = scheduleTime;
    if (room != null) updates['room'] = room;
    if (semester != null) updates['semester'] = semester;
    if (clearLecturer2) {
      updates['lecturer2_id'] = null;
    } else if (lecturer2Id != null) {
      updates['lecturer2_id'] = lecturer2Id;
    }

    await _client
        .from(SupabaseConstants.coursesTable)
        .update(updates)
        .eq('id', courseId);
  }

  Future<void> deleteCourse(String courseId) async {
    await _client
        .from(SupabaseConstants.coursesTable)
        .delete()
        .eq('id', courseId);
  }

  Future<void> enrollStudent({
    required String studentId,
    required String courseId,
  }) async {
    await _client.from(SupabaseConstants.enrollmentsTable).upsert({
      'student_id': studentId,
      'course_id': courseId,
    });
  }

  Future<void> unenrollStudent({
    required String studentId,
    required String courseId,
  }) async {
    await _client
        .from(SupabaseConstants.enrollmentsTable)
        .delete()
        .eq('student_id', studentId)
        .eq('course_id', courseId);
  }

  Future<List<Map<String, dynamic>>> getEnrolledStudents(
    String courseId,
  ) async {
    final data = await _client
        .from(SupabaseConstants.enrollmentsTable)
        .select('''
          profiles!inner(id, full_name, nim_or_nip, prodi)
        ''')
        .eq('course_id', courseId);

    return (data as List)
        .map((e) => e['profiles'] as Map<String, dynamic>)
        .toList();
  }
}
