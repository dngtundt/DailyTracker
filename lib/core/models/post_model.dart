import 'user_model.dart';

class PostModel {
  final String? id;
  final String adminId;
  final String adminName;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final List<String> targetCountries;
  final List<String> targetRanks;
  final List<String> targetGenders;
  final List<String> targetBmiLevels;
  final List<String> viewedUserIds;

  PostModel({
    this.id,
    required this.adminId,
    required this.adminName,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.targetCountries = const [],
    this.targetRanks = const [],
    this.targetGenders = const [],
    this.targetBmiLevels = const [],
    this.viewedUserIds = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String?,
      adminId: map['adminId'] as String,
      adminName: map['adminName'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      targetCountries: _stringList(map['targetCountries']),
      targetRanks: _stringList(map['targetRanks']),
      targetGenders: _stringList(map['targetGenders']),
      targetBmiLevels: _stringList(map['targetBmiLevels']),
      viewedUserIds: _stringList(map['viewedUserIds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'adminId': adminId,
      'adminName': adminName,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'targetCountries': targetCountries,
      'targetRanks': targetRanks,
      'targetGenders': targetGenders,
      'targetBmiLevels': targetBmiLevels,
      'viewedUserIds': viewedUserIds,
    };
  }

  bool appliesToUser(UserModel user) {
    final countryMatch = targetCountries.isEmpty ||
        (user.country != null && targetCountries.contains(user.country));
    final rankMatch = targetRanks.isEmpty || targetRanks.contains(user.rank);
    final genderMatch = targetGenders.isEmpty ||
        (user.gender != null && targetGenders.contains(user.gender));
    final bmiMatch =
        targetBmiLevels.isEmpty || targetBmiLevels.contains(user.bmiLevelKey);

    return countryMatch && rankMatch && genderMatch && bmiMatch;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
