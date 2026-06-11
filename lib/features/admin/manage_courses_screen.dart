import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/models/course_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/course_service.dart';
import '../../core/services/auth_service.dart';
import '../../shared/providers/course_provider.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final AuthService _authService = AuthService();
  List<UserModel> _lecturers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<CourseProvider>().loadAllCourses();
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('role', 'dosen')
          .order('full_name');
      if (mounted) {
        setState(() {
          _lecturers = (data as List).map((e) => UserModel.fromMap(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading lecturers: $e');
    }
  }

  void _showCourseDialog([CourseModel? course]) {
    final isEdit = course != null;
    final codeCtrl = TextEditingController(text: course?.code);
    final nameCtrl = TextEditingController(text: course?.name);
    final classCtrl = TextEditingController(text: course?.classGroup);
    final dayCtrl = TextEditingController(text: course?.scheduleDay);
    final timeCtrl = TextEditingController(text: course?.scheduleTime);
    final roomCtrl = TextEditingController(text: course?.room);
    String? selectedLecturerId = course?.lecturerId;
    String? selectedLecturer2Id = course?.lecturer2Id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.grey600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(isEdit ? 'Edit Mata Kuliah' : 'Tambah Mata Kuliah', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
              const SizedBox(height: 20),
              CustomTextField(
                label: 'Kode MK',
                hint: 'Contoh: TI301',
                controller: codeCtrl,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nama Mata Kuliah',
                hint: 'Contoh: Algoritma dan Pemrograman',
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Kelas (Opsional)',
                hint: 'Contoh: A, B, atau Reguler',
                controller: classCtrl,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Hari (Opsional)',
                hint: 'Contoh: Senin',
                controller: dayCtrl,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Jam (Opsional)',
                hint: 'Contoh: 08:00 - 10:00',
                controller: timeCtrl,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Ruang (Opsional)',
                hint: 'Contoh: Lab A201',
                controller: roomCtrl,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLecturerId,
                dropdownColor: AppColors.white,
                style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
                decoration: InputDecoration(
                  labelText: 'Dosen Pengampu Utama',
                  labelStyle: AppTextStyles.body.copyWith(color: AppColors.grey500),
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
                ),
                items: _lecturers.map((UserModel user) {
                  return DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(user.fullName),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setModalState(() {
                    selectedLecturerId = newValue;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedLecturer2Id,
                dropdownColor: AppColors.white,
                style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
                decoration: InputDecoration(
                  labelText: 'Dosen Pengampu Kedua (Opsional)',
                  labelStyle: AppTextStyles.body.copyWith(color: AppColors.grey500),
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
                ),
                items: _lecturers.map((UserModel user) {
                  return DropdownMenuItem<String>(
                    value: user.id,
                    child: Text(user.fullName),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setModalState(() {
                    selectedLecturer2Id = newValue;
                  });
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Simpan',
                onPressed: () async {
                  if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty || selectedLecturerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kode, Nama, dan Dosen Utama wajib diisi')),
                    );
                    return;
                  }
                  if (selectedLecturerId == selectedLecturer2Id) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dosen 1 dan Dosen 2 tidak boleh sama')),
                    );
                    return;
                  }

                  final success = isEdit
                      ? await context.read<CourseProvider>().updateCourse(
                          courseId: course.id,
                          code: codeCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          classGroup: classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim(),
                          lecturerId: selectedLecturerId!,
                          lecturer2Id: selectedLecturer2Id,
                          scheduleDay: dayCtrl.text.trim().isEmpty ? null : dayCtrl.text.trim(),
                          scheduleTime: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
                          room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                        )
                      : await context.read<CourseProvider>().createCourse(
                          code: codeCtrl.text.trim(),
                          name: nameCtrl.text.trim(),
                          classGroup: classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim(),
                          lecturerId: selectedLecturerId!,
                          lecturer2Id: selectedLecturer2Id,
                          scheduleDay: dayCtrl.text.trim().isEmpty ? null : dayCtrl.text.trim(),
                          scheduleTime: timeCtrl.text.trim().isEmpty ? null : timeCtrl.text.trim(),
                          room: roomCtrl.text.trim().isEmpty ? null : roomCtrl.text.trim(),
                        );
                  if (ctx.mounted) {
                    if (success) {
                      Navigator.pop(ctx);
                    } else {
                      final errorMsg = context.read<CourseProvider>().error ?? 'Terjadi kesalahan saat menyimpan.';
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: AppColors.danger));
                    }
                  }
                },
              ),
            ],
          ),
        ),
          );
      }),
    );
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
          onPressed: () => context.pop(),
        ),
        title: Text('Manajemen Mata Kuliah', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.white),
            onPressed: () => _showCourseDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah MK', style: AppTextStyles.label),
      ),
      body: courses.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : courses.courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64,
                        color: AppColors.grey700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada mata kuliah',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: courses.courses.length,
                    itemBuilder: (ctx, i) {
                      final c = courses.courses[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.book_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nameWithClass,
                                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${c.code}${c.room != null ? ' • ${c.room}' : ''}',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                                  ),
                                  if (c.scheduleDay != null)
                                    Text(
                                      c.scheduleDisplay,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [c.lecturerName, c.lecturer2Name]
                                        .where((n) => n != null && n.isNotEmpty)
                                        .join(' & '),
                                    style: AppTextStyles.caption.copyWith(color: AppColors.adminPrimary),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.grey500,
                              ),
                              color: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.white,
                                      title: Text(
                                        'Hapus MK?',
                                        style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark),
                                      ),
                                      content: Text(
                                        'Mata kuliah "${c.name}" akan dihapus.',
                                        style: AppTextStyles.body.copyWith(color: AppColors.grey600),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.danger,
                                          ),
                                          child: const Text('Hapus'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && ctx.mounted) {
                                    await context
                                        .read<CourseProvider>()
                                        .deleteCourse(c.id);
                                  }
                                } else if (v == 'edit') {
                                  _showCourseDialog(c);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_rounded,
                                        color: AppColors.accentLight,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Edit', style: AppTextStyles.body),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_rounded,
                                        color: AppColors.danger,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Hapus', style: AppTextStyles.body.copyWith(color: AppColors.primaryDark)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
