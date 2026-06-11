import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/models/user_model.dart';
import '../../core/constants/supabase_constants.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/custom_button.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final _client = Supabase.instance.client;
  late TabController _tabCtrl;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final data = await _client
        .from(SupabaseConstants.profilesTable)
        .select()
        .order('full_name');
    setState(() {
      _allUsers = (data as List).map((e) => UserModel.fromMap(e)).toList();
      _isLoading = false;
    });
  }

  List<UserModel> get _filtered {
    final tab = _tabCtrl.index;
    return _allUsers.where((u) {
      final matchSearch = _search.isEmpty ||
          u.fullName.toLowerCase().contains(_search.toLowerCase()) ||
          u.nimOrNip.toLowerCase().contains(_search.toLowerCase());
      final matchRole = tab == 0 ||
          (tab == 1 && u.isMahasiswa) ||
          (tab == 2 && u.isDosen);
      return matchSearch && matchRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBg,
      appBar: AppBar(
        backgroundColor: AppColors.adminPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Manajemen User', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withOpacity(0.6),
          labelStyle: AppTextStyles.label,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Mahasiswa'),
            Tab(text: 'Dosen'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: AppTextStyles.body.copyWith(color: AppColors.primaryDark),
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIM/NIP...',
                hintStyle: AppTextStyles.body.copyWith(
                  color: AppColors.grey600,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.grey500,
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    color: AppColors.accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final user = _filtered[i];
                        return _UserCard(user: user);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/admin/register');
          _loadUsers();
        },
        backgroundColor: AppColors.adminPrimary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text('Tambah User', style: AppTextStyles.label.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  Color get _roleColor {
    switch (user.role) {
      case UserRole.mahasiswa:
        return AppColors.accent;
      case UserRole.dosen:
        return AppColors.success;
      case UserRole.admin:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          CircleAvatar(
            radius: 22,
            backgroundColor: _roleColor.withOpacity(0.15),
            child: Text(
              user.initials,
              style: AppTextStyles.label.copyWith(color: _roleColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.primaryDark),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.nimOrNip} • ${user.prodi ?? '-'}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              user.role.displayName,
              style: AppTextStyles.labelSmall.copyWith(color: _roleColor),
            ),
          ),
        ],
      ),
    );
  }
}
