import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/challenge_model.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  List<ChallengeModel> _challenges = [];
  bool _loading = true;
  int _totalEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final challenges = await FirestoreService.instance.getChallengesForDate(
      today,
      user.id!,
      user: user,
    );
    final earned = challenges
        .where((c) => c.isCompleted)
        .fold(0, (sum, c) => sum + c.points);
    if (mounted) {
      setState(() {
        _challenges = challenges;
        _totalEarned = earned;
        _loading = false;
      });
    }
  }

  Future<void> _completeChallenge(ChallengeModel challenge) async {
    if (challenge.isCompleted) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    final completedNow = await FirestoreService.instance.completeChallenge(
      user.id!,
      challenge.id!,
    );
    if (!completedNow) return;
    await auth.addPoints(challenge.points);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Text('🎉 ', style: TextStyle(fontSize: 18)),
            Text('+${challenge.points} điểm! Thử thách hoàn thành!'),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      _loadChallenges();
    }
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'fitness':
        return {
          'color': AppColors.accent,
          'icon': Icons.fitness_center_rounded,
          'label': 'Thể thao'
        };
      case 'nutrition':
        return {
          'color': AppColors.success,
          'icon': Icons.restaurant_rounded,
          'label': 'Dinh dưỡng'
        };
      case 'mindset':
        return {
          'color': AppColors.primary,
          'icon': Icons.self_improvement_rounded,
          'label': 'Tâm thần'
        };
      case 'productivity':
        return {
          'color': AppColors.warning,
          'icon': Icons.bolt_rounded,
          'label': 'Năng suất'
        };
      default:
        return {
          'color': AppColors.secondary,
          'icon': Icons.star_rounded,
          'label': 'Khác'
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final completed = _challenges.where((c) => c.isCompleted).length;
    final total = _challenges.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Thử thách hôm nay',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              _buildProgressHeader(completed, total, user),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _challenges.length,
                  itemBuilder: (context, index) {
                    return _buildChallengeCard(_challenges[index], index);
                  },
                ),
              ),
            ]),
    );
  }

  Widget _buildProgressHeader(int completed, int total, user) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('$completed/$total thử thách',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Điểm kiếm được',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text('+$_totalEarned',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24)),
          ]),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress == 1.0
              ? '🎉 Xuất sắc! Bạn hoàn thành tất cả!'
              : '${(progress * 100).toStringAsFixed(0)}% hoàn thành',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ]),
    ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97));
  }

  Widget _buildChallengeCard(ChallengeModel challenge, int index) {
    final style = _getCategoryStyle(challenge.category);
    final color = style['color'] as Color;

    return GestureDetector(
      onTap: () => _completeChallenge(challenge),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: challenge.isCompleted
              ? AppColors.success.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: challenge.isCompleted
                ? AppColors.success.withOpacity(0.4)
                : color.withOpacity(0.3),
            width: challenge.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          // Category icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: challenge.isCompleted
                  ? AppColors.success.withOpacity(0.15)
                  : color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              challenge.isCompleted
                  ? Icons.check_circle_rounded
                  : style['icon'] as IconData,
              color: challenge.isCompleted ? AppColors.success : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    color: challenge.isCompleted
                        ? AppColors.textSecondary
                        : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: challenge.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(challenge.description,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4)),
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(style['label'] as String,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
              ])),
          // Points badge
          const SizedBox(width: 8),
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: challenge.isCompleted
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text('+${challenge.points}',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
                Text('điểm',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 10)),
              ]),
            ),
          ]),
        ]),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 70))
        .fadeIn()
        .slideX(begin: 0.05);
  }
}
