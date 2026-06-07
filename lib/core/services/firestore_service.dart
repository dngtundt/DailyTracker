import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/activity_template_model.dart';
import '../models/challenge_model.dart';
import '../models/post_model.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Users ─────────────────────────────────────────────────────────────

  Future<void> insertUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection('users').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final snap =
        await _db.collection('users').orderBy('points', descending: true).get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserModel.fromMap(data);
    }).toList();
  }

  Future<void> updateUser(UserModel user) async {
    if (user.id != null) {
      await _db.collection('users').doc(user.id).update(user.toMap());
    }
  }

  Future<void> updateUserBodyStats({
    required String userId,
    required double heightCm,
    required double weightKg,
  }) async {
    await _db.collection('users').doc(userId).update({
      'heightCm': heightCm,
      'weightKg': weightKg,
    });
  }

  // ── Activities ────────────────────────────────────────────────────────

  Future<void> insertActivity(ActivityModel a) async {
    final doc = _db.collection('activities').doc();
    doc
        .set(a.toMap())
        .catchError((e) => debugPrint("Offline/Error insert: $e"));
  }

  Future<List<ActivityModel>> getActivitiesForDate(
      String userId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final snap = await _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: dateStr)
        // Removed .orderBy('startTime') to avoid requiring a composite index
        .get();

    final activities = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ActivityModel.fromMap(data);
    }).toList();

    // Sort locally by startTime
    activities.sort((a, b) => a.startTime.compareTo(b.startTime));
    return activities;
  }

  Future<List<ActivityModel>> getRecentActivities(String userId,
      {int days = 7}) async {
    final snap = await _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        // Removed .orderBy('createdAt', descending: true) to avoid requiring a composite index
        .get();

    final activities = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ActivityModel.fromMap(data);
    }).toList();

    // Sort locally by createdAt descending
    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return activities.where((a) => a.date.isAfter(cutoff)).toList();
  }

  Future<void> updateActivityDone(String id, bool isDone) async {
    _db
        .collection('activities')
        .doc(id)
        .update({'isDone': isDone}).catchError((e) => debugPrint('$e'));
  }

  Future<void> deleteActivity(String id) async {
    _db
        .collection('activities')
        .doc(id)
        .delete()
        .catchError((e) => debugPrint('$e'));
  }

  Future<List<ActivityModel>> copyYesterdayActivities(
      String userId, DateTime targetDate) async {
    final yesterday = targetDate.subtract(const Duration(days: 1));
    final yesterdayActs = await getActivitiesForDate(userId, yesterday);

    final List<ActivityModel> copiedActs = [];

    for (final act in yesterdayActs) {
      final copy = ActivityModel(
        userId: userId,
        title: act.title,
        description: act.description,
        date: targetDate,
        startTime: act.startTime,
        endTime: act.endTime,
        category: act.category,
        hasReminder: act.hasReminder,
        reminderTime: act.hasReminder ? act.startTime : null,
        isDone: false,
        createdAt: DateTime.now(),
      );

      final docRef = _db.collection('activities').doc();
      docRef.set(copy.toMap()).catchError((e) => debugPrint('$e'));

      final newMap = copy.toMap();
      newMap['id'] = docRef.id;
      copiedActs.add(ActivityModel.fromMap(newMap));
    }

    return copiedActs;
  }

  Future<List<ActivityModel>> getSuggestedActivities(String userId) async {
    final snap = await _db
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .get();

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final Map<String, ActivityModel> uniqueActs = {};
    final Map<String, int> frequencies = {};

    for (final doc in snap.docs) {
      final data = doc.data();
      data['id'] = doc.id;
      final act = ActivityModel.fromMap(data);

      if (act.date.isAfter(thirtyDaysAgo)) {
        final key = act.title.trim().toLowerCase();
        frequencies[key] = (frequencies[key] ?? 0) + 1;

        if (!uniqueActs.containsKey(key) ||
            act.createdAt.isAfter(uniqueActs[key]!.createdAt)) {
          uniqueActs[key] = act;
        }
      }
    }

    final sortedKeys = frequencies.keys.toList()
      ..sort((a, b) => frequencies[b]!.compareTo(frequencies[a]!));

    final List<ActivityModel> topSuggestions = [];
    for (final key in sortedKeys.take(5)) {
      if (uniqueActs.containsKey(key)) {
        topSuggestions.add(uniqueActs[key]!);
      }
    }

    return topSuggestions;
  }

  Future<ActivityTemplateModel?> getDailyTemplate(String userId) async {
    final doc = await _db.collection('activity_templates').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    data['userId'] = userId;
    return ActivityTemplateModel.fromMap(data);
  }

  Future<void> saveDailyTemplate({
    required String userId,
    required String name,
    required List<ActivityModel> activities,
  }) async {
    final template = ActivityTemplateModel(
      userId: userId,
      name: name,
      updatedAt: DateTime.now(),
      items: activities
          .map(
            (activity) => ActivityTemplateItem(
              title: activity.title,
              description: activity.description,
              startTime: activity.startTime,
              endTime: activity.endTime,
              category: activity.category,
              hasReminder: activity.hasReminder,
              reminderTime: activity.reminderTime ??
                  (activity.hasReminder ? activity.startTime : null),
            ),
          )
          .toList(),
    );

    await _db
        .collection('activity_templates')
        .doc(userId)
        .set(template.toMap(), SetOptions(merge: true));
  }

  Future<List<ActivityModel>> applyDailyTemplate({
    required String userId,
    required DateTime targetDate,
    bool replaceExisting = false,
  }) async {
    final template = await getDailyTemplate(userId);
    if (template == null || template.items.isEmpty) return [];

    if (replaceExisting) {
      final existing = await getActivitiesForDate(userId, targetDate);
      final batch = _db.batch();
      for (final activity in existing) {
        if (activity.id != null) {
          batch.delete(_db.collection('activities').doc(activity.id));
        }
      }
      await batch.commit();
    }

    final List<ActivityModel> created = [];
    for (final item in template.items) {
      final docRef = _db.collection('activities').doc();
      final activity = ActivityModel(
        id: docRef.id,
        userId: userId,
        title: item.title,
        description: item.description,
        date: targetDate,
        startTime: item.startTime,
        endTime: item.endTime,
        category: item.category,
        hasReminder: item.hasReminder,
        reminderTime:
            item.reminderTime ?? (item.hasReminder ? item.startTime : null),
        isDone: false,
        createdAt: DateTime.now(),
      );

      await docRef.set(activity.toMap());
      created.add(activity);
    }

    created.sort((a, b) => a.startTime.compareTo(b.startTime));
    return created;
  }

  // ── Challenges ────────────────────────────────────────────────────────

  Future<void> insertChallenge(ChallengeModel challenge) async {
    final data = challenge.toMap();
    data['createdAt'] ??= DateTime.now().toIso8601String();
    await _db.collection('challenges').add(data);
  }

  Future<List<ChallengeModel>> getChallengesForDate(
    String date,
    String userId, {
    UserModel? user,
  }) async {
    final snap = await _db.collection('challenges').get();

    final targetUser = user ?? await getUserById(userId);
    if (targetUser == null) return [];

    final List<ChallengeModel> challenges = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      final challenge = ChallengeModel.fromMap(data);
      // Check if target date is between startDate and endDate (lexicographical comparison YYYY-MM-DD)
      final targetDate = date;
      final isWithinRange = targetDate.compareTo(challenge.startDate) >= 0 &&
                            targetDate.compareTo(challenge.endDate) <= 0;
      if (!isWithinRange) {
        continue;
      }

      if (!challenge.appliesToUser(targetUser)) {
        continue;
      }

      final ucSnap = await _db
          .collection('user_challenges')
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: doc.id)
          .get();

      challenges.add(
        challenge.copyWith(isCompleted: ucSnap.docs.isNotEmpty),
      );
    }

    challenges.sort((a, b) {
      return b.createdAtForSort.compareTo(a.createdAtForSort);
    });
    return challenges;
  }

  Future<bool> completeChallenge(String userId, String challengeId) async {
    final completionRef =
        _db.collection('user_challenges').doc('${userId}_$challengeId');

    return _db.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(completionRef);
      if (existing.exists) {
        return false;
      }

      transaction.set(completionRef, {
        'userId': userId,
        'challengeId': challengeId,
        'completedAt': DateTime.now().toIso8601String(),
      });
      return true;
    });
  }

  Future<List<ChallengeModel>> getAllChallenges() async {
    final snap = await _db.collection('challenges').get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return ChallengeModel.fromMap(data);
    }).toList();
  }

  Future<void> deleteChallenge(String id) async {
    await _db.collection('challenges').doc(id).delete();
  }

  Future<void> updateChallenge(ChallengeModel challenge) async {
    if (challenge.id != null) {
      await _db.collection('challenges').doc(challenge.id).update(challenge.toMap());
    }
  }

  // ── Posts ─────────────────────────────────────────────────────────────

  Future<void> insertPost(PostModel post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Future<List<PostModel>> getAllPosts() async {
    final snap = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return PostModel.fromMap(data);
    }).toList();
  }

  Future<void> deletePost(String id) async {
    await _db.collection('posts').doc(id).delete();
  }

  Future<void> updatePost(PostModel post) async {
    if (post.id != null) {
      await _db.collection('posts').doc(post.id).update(post.toMap());
    }
  }

  Future<void> viewPost(String postId, String userId) async {
    await _db.collection('posts').doc(postId).update({
      'viewedUserIds': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> toggleLikePost(String postId, String userId) async {
    final postDoc = _db.collection('posts').doc(postId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(postDoc);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final likes = List<String>.from(data['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      transaction.update(postDoc, {'likes': likes});
    });
  }

  Future<void> addCommentToPost(String postId, CommentModel comment) async {
    final postDoc = _db.collection('posts').doc(postId);
    await postDoc.update({
      'comments': FieldValue.arrayUnion([comment.toMap()])
    });
  }

  Stream<PostModel> getPostStream(String postId) {
    return _db.collection('posts').doc(postId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      data['id'] = doc.id;
      return PostModel.fromMap(data);
    });
  }

  Future<int> getChallengeCompletionCount(String challengeId) async {
    final snap = await _db
        .collection('user_challenges')
        .where('challengeId', isEqualTo: challengeId)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
