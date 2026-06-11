import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.mahasiswa;
  String? _selectedProdi;
  final List<String> _prodiOptions = [
    'Teknik Sipil',
    'Informatika',
    'Perencanaan Wilayah dan Kota',
    'Sistem Informasi',
    'Arsitektur',
  ];
  int _step = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nimCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.adminSignUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      nimOrNip: _nimCtrl.text.trim(),
      role: _selectedRole,
      prodi: _selectedProdi,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengguna berhasil ditambahkan!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.pop();
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text('Tambah Pengguna', style: AppTextStyles.h3.copyWith(color: AppColors.primaryDark)),
                  ],
                ),
              ),
              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(2, (i) {
                    final active = i <= _step;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: active ? AppColors.adminPrimary : AppColors.grey200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _step == 0 ? _buildStep1() : _buildStep2(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: _step == 0
                    ? CustomButton(
                        label: 'Lanjut',
                        onPressed: () {
                          if (_nameCtrl.text.isNotEmpty &&
                              _nimCtrl.text.isNotEmpty &&
                              (_selectedRole != UserRole.mahasiswa || _selectedProdi != null)) {
                            setState(() => _step = 1);
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'Kembali',
                              onPressed: () => setState(() => _step = 0),
                              isOutlined: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: CustomButton(
                              label: 'Tambah',
                              onPressed: _register,
                              isLoading: auth.isLoading,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Pribadi', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        Text('Lengkapi data diri Anda', style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
        const SizedBox(height: 28),
        // Role selector
        Text('Daftar sebagai', style: AppTextStyles.label.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 10),
        Row(
          children: UserRole.values
              .where((r) => r != UserRole.admin)
              .map((role) {
                final selected = _selectedRole == role;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = role),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: role != UserRole.dosen ? 10 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.adminPrimary : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.adminPrimary
                              : AppColors.grey200,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            role == UserRole.mahasiswa
                                ? Icons.school_rounded
                                : Icons.person_rounded,
                            color: selected ? Colors.white : AppColors.grey400,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            role.displayName,
                            style: AppTextStyles.label.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
        const SizedBox(height: 20),
        CustomTextField(
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap',
          controller: _nameCtrl,
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.grey500,
            size: 20,
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: _selectedRole == UserRole.mahasiswa ? 'NIM' : 'NIP',
          hint: _selectedRole == UserRole.mahasiswa
              ? 'Nomor Induk Mahasiswa'
              : 'Nomor Induk Pegawai',
          controller: _nimCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(
            Icons.badge_outlined,
            color: AppColors.grey500,
            size: 20,
          ),
          validator: (v) =>
              v == null || v.isEmpty ? 'NIM/NIP wajib diisi' : null,
        ),
        if (_selectedRole == UserRole.mahasiswa) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProdi,
            dropdownColor: AppColors.white,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey500),
            style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
            decoration: InputDecoration(
              labelText: 'Program Studi',
              labelStyle: AppTextStyles.body.copyWith(color: AppColors.grey500),
              prefixIcon: const Icon(
                Icons.account_balance_outlined,
                color: AppColors.grey500,
                size: 20,
              ),
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
            items: _prodiOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedProdi = newValue;
              });
            },
            validator: (v) => v == null || v.isEmpty ? 'Program Studi wajib diisi' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informasi Akun', style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
        const SizedBox(height: 6),
        Text('Buat email dan password Anda', style: AppTextStyles.body.copyWith(color: AppColors.grey600)),
        const SizedBox(height: 28),
        CustomTextField(
          label: 'Email',
          hint: 'contoh@email.com',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: AppColors.grey500,
            size: 20,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email wajib diisi';
            if (!v.contains('@')) return 'Format email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Password',
          hint: 'Minimal 6 karakter',
          controller: _passCtrl,
          isPassword: true,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.grey500,
            size: 20,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password wajib diisi';
            if (v.length < 6) return 'Password minimal 6 karakter';
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Konfirmasi Password',
          hint: 'Ulangi password',
          controller: _confirmCtrl,
          isPassword: true,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.grey500,
            size: 20,
          ),
          validator: (v) {
            if (v != _passCtrl.text) return 'Password tidak cocok';
            return null;
          },
        ),
      ],
    );
  }
}
