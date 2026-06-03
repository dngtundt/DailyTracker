class UserModel {
  final String? id;
  final String username;
  final String email;
  final String password;
  final String role; // 'user' | 'admin'
  final int points;
  final String rank;
  final String? avatarUrl;
  final DateTime createdAt;
  // ── Extended profile fields ──────────────────────────────────
  final String? gender; // 'Nam' | 'Nữ' | 'Khác'
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? country;
  final String? occupation;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.points,
    required this.rank,
    this.avatarUrl,
    required this.createdAt,
    this.gender,
    this.age,
    this.heightCm,
    this.weightKg,
    this.country,
    this.occupation,
  });

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm! <= 0) return null;
    return weightKg! / ((heightCm! / 100) * (heightCm! / 100));
  }

  String get bmiLabel {
    final b = bmi;
    if (b == null) return '';
    if (b < 18.5) return 'Thiếu cân';
    if (b < 25.0) return 'Bình thường';
    if (b < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  String get bmiLevelKey {
    final b = bmi;
    if (b == null) return 'unknown';
    if (b < 18.5) return 'underweight';
    if (b < 25.0) return 'normal';
    if (b < 30.0) return 'overweight';
    return 'obese';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      points: map['points'] as int,
      rank: map['rank'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      gender: map['gender'] as String?,
      age: map['age'] as int?,
      heightCm:
          map['heightCm'] != null ? (map['heightCm'] as num).toDouble() : null,
      weightKg:
          map['weightKg'] != null ? (map['weightKg'] as num).toDouble() : null,
      country: map['country'] as String?,
      occupation: map['occupation'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'points': points,
      'rank': rank,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'gender': gender,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'country': country,
      'occupation': occupation,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? role,
    int? points,
    String? rank,
    String? avatarUrl,
    DateTime? createdAt,
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? country,
    String? occupation,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      country: country ?? this.country,
      occupation: occupation ?? this.occupation,
    );
  }
}
