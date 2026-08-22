enum UserRole {
  warga,
  bpbd,
  teknisi,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.warga:
        return 'Warga / Masyarakat';
      case UserRole.bpbd:
        return 'Operator BPBD / SAR';
      case UserRole.teknisi:
        return 'Teknisi Lapangan IoT';
    }
  }

  String get code {
    switch (this) {
      case UserRole.warga:
        return 'warga';
      case UserRole.bpbd:
        return 'bpbd';
      case UserRole.teknisi:
        return 'teknisi';
    }
  }

  static UserRole fromCode(String code) {
    switch (code) {
      case 'bpbd':
        return UserRole.bpbd;
      case 'teknisi':
        return UserRole.teknisi;
      default:
        return UserRole.warga;
    }
  }
}

class UserProfile {
  final String uid;
  final String name;
  final UserRole role;
  final String? phone;
  final String? location;

  UserProfile({
    required this.uid,
    required this.name,
    required this.role,
    this.phone,
    this.location,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      uid: 'user_default',
      name: 'Tim TRILOGY (MAGE 12)',
      role: UserRole.bpbd,
      phone: '+62 812-3456-7890',
      location: 'SMK Budi Luhur, Kota Tangerang',
    );
  }
}
