import 'package:flutter/material.dart';
import '../../../core/models/course_model.dart';
import '../../../core/services/course_service.dart';

class CourseProvider extends ChangeNotifier {
  final CourseService _service = CourseService();

  List<CourseModel> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<CourseModel> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCoursesByStudent(String studentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _courses = await _service.getCoursesByStudent(studentId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCoursesByLecturer(String lecturerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _courses = await _service.getCoursesByLecturer(lecturerId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _courses = await _service.getAllCourses();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createCourse({
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
    try {
      final course = await _service.createCourse(
        code: code,
        name: name,
        classGroup: classGroup,
        lecturerId: lecturerId,
        lecturer2Id: lecturer2Id,
        scheduleDay: scheduleDay,
        scheduleTime: scheduleTime,
        room: room,
        semester: semester,
        creditHours: creditHours,
      );
      _courses = [..._courses, course];
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('courses_code_key') || e.toString().contains('courses_code_class_key') || e.toString().contains('duplicate key')) {
        _error = 'Kode MK & Kelas ini sudah terdaftar! Gunakan kombinasi yang unik.';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCourse({
    required String courseId,
    String? code,
    String? name,
    String? classGroup,
    String? lecturerId,
    String? lecturer2Id,
    String? scheduleDay,
    String? scheduleTime,
    String? room,
  }) async {
    try {
      await _service.updateCourse(
        courseId: courseId,
        code: code,
        name: name,
        classGroup: classGroup,
        lecturerId: lecturerId,
        lecturer2Id: lecturer2Id,
        scheduleDay: scheduleDay,
        scheduleTime: scheduleTime,
        room: room,
      );
      // Refresh the list from server to get updated relationships (like lecturer names)
      await loadAllCourses();
      return true;
    } catch (e) {
      if (e.toString().contains('courses_code_key') || e.toString().contains('courses_code_class_key') || e.toString().contains('duplicate key')) {
        _error = 'Kode MK & Kelas ini sudah terdaftar! Gunakan kombinasi yang unik.';
      } else {
        _error = e.toString();
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCourse(String courseId) async {
    try {
      await _service.deleteCourse(courseId);
      _courses = _courses.where((c) => c.id != courseId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
