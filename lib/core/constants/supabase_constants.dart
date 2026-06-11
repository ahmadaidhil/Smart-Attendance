// ============================================================
// SUPABASE CONSTANTS
// ============================================================
// Ganti nilai di bawah dengan credential Supabase Anda.
// Buat project di https://supabase.com → Settings → API
// ============================================================

class SupabaseConstants {
  /// Project URL dari Supabase Dashboard → Settings → API → Project URL
  static const String supabaseUrl = 'https://flcetlgtgqapxfdackai.supabase.co';

  /// Anon (public) key dari Supabase Dashboard → Settings → API → Project API Keys
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZsY2V0bGd0Z3FhcHhmZGFja2FpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4MDk1OTgsImV4cCI6MjA5NjM4NTU5OH0.2DVhA1bhqa2OXNGkFesD8qa_krA_1rdayHYKC174XQ4';

  // Table names
  static const String profilesTable = 'profiles';
  static const String coursesTable = 'courses';
  static const String enrollmentsTable = 'enrollments';
  static const String attendanceSessionsTable = 'attendance_sessions';
  static const String attendancesTable = 'attendances';

  // Storage buckets
  static const String avatarsBucket = 'avatars';

  // QR token expiry in minutes
  static const int qrExpiryMinutes = 15;

  // Default check-in grace period (minutes after session start = "on time")
  static const int gracePeriodMinutes = 15;

  // Default GPS radius in meters
  static const int defaultRadiusMeters = 100;
}
