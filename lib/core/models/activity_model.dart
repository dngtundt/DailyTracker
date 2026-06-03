class ActivityModel {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final DateTime date;
  final String startTime; // HH:mm
  final String? endTime;
  final String category; // work, sport, food, rest, other
  final String? color;
  final bool hasReminder;
  final String? reminderTime;
  final bool isDone;
  final DateTime createdAt;

  ActivityModel({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.category,
    this.color,
    this.hasReminder = false,
    this.reminderTime,
    this.isDone = false,
    required this.createdAt,
  });

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'] as String?,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String?,
      category: map['category'] as String,
      color: map['color'] as String?,
      hasReminder: map['hasReminder'] == true || map['hasReminder'] == 1,
      reminderTime: map['reminderTime'] as String?,
      isDone: map['isDone'] == true || map['isDone'] == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'startTime': startTime,
      'endTime': endTime,
      'category': category,
      'color': color,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ActivityModel copyWith({bool? isDone}) {
    return ActivityModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      date: date,
      startTime: startTime,
      endTime: endTime,
      category: category,
      color: color,
      hasReminder: hasReminder,
      reminderTime: reminderTime,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}
