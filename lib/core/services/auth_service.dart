import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        await refreshUser();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await refreshUser();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'Email không tồn tại';
      if (e.code == 'wrong-password') return 'Mật khẩu không đúng';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
    String role = 'user',
    String? gender,
    int? age,
    double? heightCm,
    double? weightKg,
    String? country,
    String? occupation,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final user = UserModel(
        id: uid,
        username: username,
        email: email,
        password:
            password, // For simplicity in this app, though normally you don't store passwords in DB
        role: email.trim().toLowerCase() == 'admin@dailytracker.com' ? 'admin' : role,
        points: 0,
        rank: 'iron',
        createdAt: DateTime.now(),
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        country: country,
        occupation: occupation,
      );

      await FirestoreService.instance.insertUser(user);
      await refreshUser();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') return 'Email đã được sử dụng';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> refreshUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      var user =
          await FirestoreService.instance.getUserById(firebaseUser.uid);
      if (user != null) {
        if (user.email.trim().toLowerCase() == 'admin@dailytracker.com' &&
            user.role != 'admin') {
          user = user.copyWith(role: 'admin');
          await FirestoreService.instance.updateUser(user);
        }
        _currentUser = user;
        notifyListeners();
      }
    }
  }

  Future<void> addPoints(int points) async {
    if (_currentUser == null) return;
    final newPoints = _currentUser!.points + points;
    final newRank = _getRank(newPoints);
    final updated = _currentUser!.copyWith(points: newPoints, rank: newRank);
    await FirestoreService.instance.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  Future<String?> updateBodyStats({
    required double heightCm,
    required double weightKg,
  }) async {
    if (_currentUser == null) return 'Người dùng chưa đăng nhập';
    if (heightCm <= 0 || weightKg <= 0)
      return 'Chiều cao và cân nặng phải lớn hơn 0';

    try {
      await FirestoreService.instance.updateUserBodyStats(
        userId: _currentUser!.id!,
        heightCm: heightCm,
        weightKg: weightKg,
      );
      _currentUser = _currentUser!.copyWith(
        heightCm: heightCm,
        weightKg: weightKg,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfile({
    required String gender,
    required int age,
    required double heightCm,
    required double weightKg,
    required String country,
    String? occupation,
  }) async {
    if (_currentUser == null) return 'Người dùng chưa đăng nhập';
    if (heightCm <= 0 || weightKg <= 0 || age <= 0) {
      return 'Thông tin nhập vào không hợp lệ';
    }

    try {
      final updated = _currentUser!.copyWith(
        gender: gender,
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
        country: country,
        occupation: occupation,
      );
      await FirestoreService.instance.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  String _getRank(int points) {
    if (points >= 15000) return 'master';
    if (points >= 8000) return 'diamond';
    if (points >= 4000) return 'platinum';
    if (points >= 1500) return 'gold';
    if (points >= 500) return 'bronze';
    return 'iron';
  }
}
