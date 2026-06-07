import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ChallengeModel {
  final String? id;
  final String title;
  final String description;
  final int points;
  final String category; // fitness, nutrition, mindset, productivity
  final String date; // YYYY-MM-DD
  final bool isCompleted;
  final String? userId;
  final List<String> targetCountries;
  final List<String> targetRanks;
  final List<String> targetGenders;
  final List<String> targetBmiLevels;
  final String? adminId;
  final String? adminName;
  final DateTime? createdAt;

  ChallengeModel({
    this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.category,
    required this.date,
    this.isCompleted = false,
    this.userId,
    this.targetCountries = const [],
    this.targetRanks = const [],
    this.targetGenders = const [],
    this.targetBmiLevels = const [],
    this.adminId,
    this.adminName,
    this.createdAt,
  });

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] as String?,
      title: map['title'] as String,
      description: map['description'] as String,
      points: map['points'] as int,
      category: map['category'] as String,
      date: map['date'] as String,
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
      userId: map['userId'] as String?,
      targetCountries: _stringList(map['targetCountries']),
      targetRanks: _stringList(map['targetRanks']),
      targetGenders: _stringList(map['targetGenders']),
      targetBmiLevels: _stringList(map['targetBmiLevels']),
      adminId: map['adminId'] as String?,
      adminName: map['adminName'] as String?,
      createdAt: _dateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'points': points,
      'category': category,
      'date': date,
      'isCompleted': isCompleted,
      if (userId != null) 'userId': userId,
      'targetCountries': targetCountries,
      'targetRanks': targetRanks,
      'targetGenders': targetGenders,
      'targetBmiLevels': targetBmiLevels,
      'adminId': adminId,
      'adminName': adminName,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  bool get appliesToAll =>
      targetCountries.isEmpty &&
      targetRanks.isEmpty &&
      targetGenders.isEmpty &&
      targetBmiLevels.isEmpty;

  bool get hasCreatedAt => createdAt != null;

  DateTime get createdAtForSort =>
      createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  bool appliesToUser(UserModel user) {
    bool countryMatch = targetCountries.isEmpty;
    if (!countryMatch && user.country != null) {
      final userCountry = user.country!.trim().toLowerCase();
      countryMatch = targetCountries.any((t) => t.trim().toLowerCase() == userCountry);
    }

    bool rankMatch = targetRanks.isEmpty;
    if (!rankMatch) {
      final userRank = user.rank.trim().toLowerCase();
      rankMatch = targetRanks.any((t) => t.trim().toLowerCase() == userRank);
    }

    bool genderMatch = targetGenders.isEmpty;
    if (!genderMatch && user.gender != null) {
      final userGender = user.gender!.trim().toLowerCase();
      genderMatch = targetGenders.any((t) => t.trim().toLowerCase() == userGender);
    }

    bool bmiMatch = targetBmiLevels.isEmpty;
    if (!bmiMatch) {
      final userBmi = user.bmiLevelKey.trim().toLowerCase();
      bmiMatch = targetBmiLevels.any((t) => t.trim().toLowerCase() == userBmi);
    }

    return countryMatch && rankMatch && genderMatch && bmiMatch;
  }

  ChallengeModel copyWith({
    bool? isCompleted,
    List<String>? targetCountries,
    List<String>? targetRanks,
    List<String>? targetGenders,
    List<String>? targetBmiLevels,
    String? adminId,
    String? adminName,
    DateTime? createdAt,
  }) {
    return ChallengeModel(
      id: id,
      title: title,
      description: description,
      points: points,
      category: category,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId,
      targetCountries: targetCountries ?? this.targetCountries,
      targetRanks: targetRanks ?? this.targetRanks,
      targetGenders: targetGenders ?? this.targetGenders,
      targetBmiLevels: targetBmiLevels ?? this.targetBmiLevels,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static DateTime? _dateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
