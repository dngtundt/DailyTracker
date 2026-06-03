class ActivityTemplateItem {
  final String title;
  final String? description;
  final String startTime;
  final String? endTime;
  final String category;
  final bool hasReminder;
  final String? reminderTime;

  const ActivityTemplateItem({
    required this.title,
    this.description,
    required this.startTime,
    this.endTime,
    required this.category,
    required this.hasReminder,
    this.reminderTime,
  });

  factory ActivityTemplateItem.fromMap(Map<String, dynamic> map) {
    return ActivityTemplateItem(
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String?,
      category: map['category'] as String,
      hasReminder: map['hasReminder'] == true,
      reminderTime: map['reminderTime'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'category': category,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime,
    };
  }
}

class ActivityTemplateModel {
  final String userId;
  final String name;
  final List<ActivityTemplateItem> items;
  final DateTime updatedAt;

  const ActivityTemplateModel({
    required this.userId,
    required this.name,
    required this.items,
    required this.updatedAt,
  });

  factory ActivityTemplateModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List<dynamic>? ?? const [];
    return ActivityTemplateModel(
      userId: map['userId'] as String,
      name: map['name'] as String? ?? 'Mẫu mặc định',
      items: rawItems
          .whereType<Map>()
          .map((item) => ActivityTemplateItem.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
