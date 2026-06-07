import 'user_model.dart';

class CommentModel {
  final String userId;
  final String username;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? 'Người dùng',
      content: map['content'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

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
  final List<String> likes;
  final List<CommentModel> comments;

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
    this.likes = const [],
    this.comments = const [],
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String?,
      adminId: map['adminId'] as String? ?? '',
      adminName: map['adminName'] as String? ?? 'Admin',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      targetCountries: _stringList(map['targetCountries']),
      targetRanks: _stringList(map['targetRanks']),
      targetGenders: _stringList(map['targetGenders']),
      targetBmiLevels: _stringList(map['targetBmiLevels']),
      viewedUserIds: _stringList(map['viewedUserIds']),
      likes: _stringList(map['likes']),
      comments: (map['comments'] as List?)
              ?.map((e) => CommentModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'likes': likes,
      'comments': comments.map((e) => e.toMap()).toList(),
    };
  }

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

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}
