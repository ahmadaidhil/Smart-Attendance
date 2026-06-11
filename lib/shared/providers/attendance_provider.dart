import 'package:flutter/material.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/session_model.dart';
import '../../../core/services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  List<AttendanceModel> _attendances = [];
  List<AttendanceModel> _sessionAttendances = [];
  SessionModel? _activeSession;
  AttendanceSummary? _summary;
  bool _isLoading = false;
  bool _isCheckingIn = false;
  String? _error;

  List<AttendanceModel> get attendances => _attendances;
  List<AttendanceModel> get sessionAttendances => _sessionAttendances;
  SessionModel? get activeSession => _activeSession;
  AttendanceSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get isCheckingIn => _isCheckingIn;
  String? get error => _error;

  Future<void> loadStudentAttendances({
    required String studentId,
    String? courseId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _attendances = await _service.getStudentAttendances(
        studentId: studentId,
        courseId: courseId,
      );
      _summary = await _service.getStudentSummary(
        studentId: studentId,
        courseId: courseId,
      );
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSessionAttendances(String sessionId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _sessionAttendances = await _service.getSessionAttendances(sessionId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<AttendanceCheckInResult> checkIn({
    required String sessionId,
    required String studentId,
    required String qrToken,
    double? latitude,
    double? longitude,
  }) async {
    _isCheckingIn = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.checkIn(
        sessionId: sessionId,
        studentId: studentId,
        qrToken: qrToken,
        latitude: latitude,
        longitude: longitude,
      );
      if (result.success && result.attendance != null) {
        _attendances = [result.attendance!, ..._attendances];
      }
      _isCheckingIn = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isCheckingIn = false;
      notifyListeners();
      return AttendanceCheckInResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

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
    final session = await _service.createSession(
      courseId: courseId,
      lecturerId: lecturerId,
      topic: topic,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      meetingNumber: meetingNumber,
      isOnline: isOnline,
    );
    _activeSession = session;
    notifyListeners();
    return session;
  }

  Future<void> closeSession(String sessionId) async {
    await _service.closeSession(sessionId);
    _activeSession = null;
    notifyListeners();
  }

  Future<void> refreshQrToken(String sessionId) async {
    final updated = await _service.refreshQrToken(sessionId);
    _activeSession = updated;
    notifyListeners();
  }

  void setActiveSession(SessionModel? session) {
    _activeSession = session;
    notifyListeners();
  }

  void updateSessionAttendances(List<AttendanceModel> list) {
    _sessionAttendances = list;
    notifyListeners();
  }

  Future<bool> updateStudentAttendanceStatus({
    required String studentId,
    required String sessionId,
    required AttendanceStatus status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateAttendanceStatus(
        studentId: studentId,
        sessionId: sessionId,
        status: status,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
