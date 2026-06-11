class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String nimOrNip;
  final UserRole role;
  final String? prodi;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.nimOrNip,
    required this.role,
    this.prodi,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String,
      nimOrNip: map['nim_or_nip'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String),
      prodi: map['prodi'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'nim_or_nip': nimOrNip,
      'role': role.value,
      'prodi': prodi,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isMahasiswa => role == UserRole.mahasiswa;
  bool get isDosen => role == UserRole.dosen;
  bool get isAdmin => role == UserRole.admin;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }

  String get firstName {
    if (fullName.contains('@')) {
      return fullName.split('@').first;
    }
    return fullName.split(' ').first;
  }

  UserModel copyWith({
    String? fullName,
    String? nimOrNip,
    String? prodi,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      nimOrNip: nimOrNip ?? this.nimOrNip,
      role: role,
      prodi: prodi ?? this.prodi,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}

enum UserRole {
  mahasiswa('mahasiswa'),
  dosen('dosen'),
  admin('admin');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.mahasiswa,
    );
  }

  String get displayName {
    switch (this) {
      case UserRole.mahasiswa:
        return 'Mahasiswa';
      case UserRole.dosen:
        return 'Dosen';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
