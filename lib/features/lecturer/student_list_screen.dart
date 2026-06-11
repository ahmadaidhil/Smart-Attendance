import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/course_model.dart';
import '../../core/services/course_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/course_provider.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final CourseService _courseService = CourseService();
  CourseModel? _selectedCourse;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<CourseProvider>().loadCoursesByLecturer(user.id);
      }
    });
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;
    setState(() => _isLoading = true);

    final students = await _courseService.getEnrolledStudents(_selectedCourse!.id);

    setState(() {
      _students = students;
      _isLoading = false;
    });
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
        title: Text('Daftar Mahasiswa', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course selector
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CourseModel>(
                value: _selectedCourse,
                isExpanded: true,
                dropdownColor: AppColors.white,
                hint: Text(
                  'Pilih Mata Kuliah',
                  style: AppTextStyles.body.copyWith(color: AppColors.grey600),
                ),
                items: courses.courses.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(
                      '${c.code} - ${c.name} (Kelas ${c.classGroup})',
                      style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedCourse = val);
                  _loadStudents();
                },
              ),
            ),
          ),

          Expanded(
            child: _selectedCourse == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 64,
                          color: AppColors.grey700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pilih mata kuliah untuk melihat mahasiswa',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.accent),
                      )
                    : _students.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada mahasiswa terdaftar',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _students.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: AppColors.grey200,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final s = _students[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          AppColors.info.withOpacity(0.15),
                                      child: Text(
                                        (s['full_name'] as String)
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: AppTextStyles.h4.copyWith(
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['full_name'] as String,
                                            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.badge_outlined,
                                                size: 14,
                                                color: AppColors.grey600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                s['nim_or_nip'] as String? ?? '-',
                                                style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                                              ),
                                              if (s['prodi'] != null) ...[
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.school_outlined,
                                                  size: 14,
                                                  color: AppColors.grey600,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    s['prodi'] as String,
                                                    style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
