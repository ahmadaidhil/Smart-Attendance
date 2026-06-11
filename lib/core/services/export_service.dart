import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance_model.dart';
import '../models/course_model.dart';
import '../utils/date_formatter.dart';

class ExportService {
  Future<void> exportToPdf({
    required CourseModel course,
    required List<Map<String, dynamic>> students,
    required List<AttendanceModel> attendances,
    required int totalSessions,
  }) async {
    final pdf = pw.Document();

    // Build student summary map
    final Map<String, Map<String, int>> summary = {};
    for (final student in students) {
      final id = student['id'] as String;
      summary[id] = {
        'hadir': 0,
        'terlambat': 0,
        'alpha': 0,
        'izin': 0,
        'sakit': 0,
      };
    }
    for (final a in attendances) {
      summary[a.studentId]?[a.status.value] =
          (summary[a.studentId]?[a.status.value] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Rekap Kehadiran – ${course.name}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Kode: ${course.code}'),
          pw.Text('Total Pertemuan: $totalSessions'),
          pw.Text(
            'Digenerate: ${DateFormatter.formatDateTime(DateTime.now())}',
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: [
              'No',
              'Nama',
              'NIM',
              'Hadir',
              'Terlambat',
              'Alpha',
              'Izin',
              'Sakit',
              '% Hadir',
            ],
            data: List.generate(students.length, (i) {
              final s = students[i];
              final sid = s['id'] as String;
              final h = summary[sid]?['hadir'] ?? 0;
              final t = summary[sid]?['terlambat'] ?? 0;
              final a = summary[sid]?['alpha'] ?? 0;
              final iz = summary[sid]?['izin'] ?? 0;
              final sk = summary[sid]?['sakit'] ?? 0;
              final pct = totalSessions > 0
                  ? (((h + t) / totalSessions) * 100).toStringAsFixed(1)
                  : '0';
              return [
                '${i + 1}',
                s['full_name'],
                s['nim_or_nip'] ?? '-',
                '$h',
                '$t',
                '$a',
                '$iz',
                '$sk',
                '$pct%',
              ];
            }),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/rekap_${course.code}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rekap Kehadiran ${course.name}',
    );
  }

  Future<void> exportToExcel({
    required CourseModel course,
    required List<Map<String, dynamic>> students,
    required List<AttendanceModel> attendances,
    required int totalSessions,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Rekap Kehadiran'];

    // Headers
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama'),
      TextCellValue('NIM'),
      TextCellValue('Hadir'),
      TextCellValue('Terlambat'),
      TextCellValue('Alpha'),
      TextCellValue('Izin'),
      TextCellValue('Sakit'),
      TextCellValue('% Kehadiran'),
    ]);

    // Build summary
    final Map<String, Map<String, int>> summary = {};
    for (final student in students) {
      final id = student['id'] as String;
      summary[id] = {
        'hadir': 0,
        'terlambat': 0,
        'alpha': 0,
        'izin': 0,
        'sakit': 0,
      };
    }
    for (final a in attendances) {
      summary[a.studentId]?[a.status.value] =
          (summary[a.studentId]?[a.status.value] ?? 0) + 1;
    }

    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      final sid = s['id'] as String;
      final h = summary[sid]?['hadir'] ?? 0;
      final t = summary[sid]?['terlambat'] ?? 0;
      final a = summary[sid]?['alpha'] ?? 0;
      final iz = summary[sid]?['izin'] ?? 0;
      final sk = summary[sid]?['sakit'] ?? 0;
      final pct = totalSessions > 0 ? ((h + t) / totalSessions) * 100 : 0.0;

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(s['full_name'] as String),
        TextCellValue(s['nim_or_nip'] as String? ?? '-'),
        IntCellValue(h),
        IntCellValue(t),
        IntCellValue(a),
        IntCellValue(iz),
        IntCellValue(sk),
        TextCellValue('${pct.toStringAsFixed(1)}%'),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/rekap_${course.code}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Rekap Kehadiran ${course.name}',
    );
  }
}
