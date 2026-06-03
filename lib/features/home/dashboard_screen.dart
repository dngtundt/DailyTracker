import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/activity_model.dart';
import '../../core/models/challenge_model.dart';
import '../../core/models/post_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/locale_provider.dart';
import '../../widgets/rank_badge.dart';
import '../challenges/challenges_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ActivityModel> _activities = [];
  List<ChallengeModel> _challenges = [];
  List<PostModel> _posts = [];
  bool _loading = true;
  late String _todayQuote;

  @override
  void initState() {
    super.initState();
    _todayQuote = AppStrings.motivationalQuotes[
        DateTime.now().day % AppStrings.motivationalQuotes.length];
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final acts =
        await FirestoreService.instance.getActivitiesForDate(user.id!, today);
    final challenges = await FirestoreService.instance.getChallengesForDate(
      todayStr,
      user.id!,
      user: user,
    );
    final posts = await FirestoreService.instance.getAllPosts();
    final filteredPosts = auth.isAdmin ? posts : posts.where((p) => p.appliesToUser(user)).toList();
    filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Async record view events for new posts
    if (!auth.isAdmin) {
      for (final post in filteredPosts) {
        if (post.id != null && !post.viewedUserIds.contains(user.id)) {
          FirestoreService.instance.viewPost(post.id!, user.id!);
        }
      }
    }

    if (mounted) {
      setState(() {
        _activities = acts;
        _challenges = challenges;
        _posts = filteredPosts;
        _loading = false;
      });
      _checkNewPosts(filteredPosts);
      _checkNewChallenges(challenges);
    }
  }

  Future<void> _checkNewPosts(List<PostModel> posts) async {
    if (posts.isEmpty) return;
    final auth = context.read<AuthService>();
    final prefs = await SharedPreferences.getInstance();
    final lastSeenId = prefs.getString('last_seen_post_id');
    final latestPost = posts.first;

    // Check if user is admin, admins don't need notifications for their own posts
    if (auth.isAdmin) return;

    if (latestPost.id != null && latestPost.id != lastSeenId) {
      prefs.setString('last_seen_post_id', latestPost.id!);

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [
              const Icon(Icons.campaign_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Thông báo mới từ Admin!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(latestPost.title,
                    style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(latestPost.content,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.5),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đã hiểu',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }
    }
  }

  Future<void> _checkNewChallenges(List<ChallengeModel> challenges) async {
    if (challenges.isEmpty) return;

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null || auth.isAdmin) return;

    final datedChallenges = <ChallengeModel>[];
    for (final challenge in challenges) {
      if (challenge.hasCreatedAt) {
        datedChallenges.add(challenge);
      }
    }
    if (datedChallenges.isEmpty) return;

    var latestChallenge = datedChallenges.first;
    for (final challenge in datedChallenges.skip(1)) {
      if (challenge.createdAtForSort
          .isAfter(latestChallenge.createdAtForSort)) {
        latestChallenge = challenge;
      }
    }
    final latestCreatedAt = latestChallenge.createdAtForSort;

    final prefs = await SharedPreferences.getInstance();
    final key = 'last_seen_challenge_created_at_${user.id}';
    final lastSeenRaw = prefs.getString(key);
    final lastSeen =
        lastSeenRaw == null ? null : DateTime.tryParse(lastSeenRaw);
    final hasNewChallenge =
        lastSeen == null || latestCreatedAt.isAfter(lastSeen);
    if (!hasNewChallenge) return;

    await prefs.setString(key, latestCreatedAt.toIso8601String());

    await NotificationService.instance.showInstantNotification(
      'Thử thách mới hôm nay',
      latestChallenge.title,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Thử thách mới cho bạn',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latestChallenge.title,
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              latestChallenge.description,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 10),
            Text(
              '+${latestChallenge.points} điểm',
              style: const TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : const Color(0xFFF0F4FF);
    if (user == null) return const SizedBox();

    final completed = _challenges.where((c) => c.isCompleted).length;
    final progress = _challenges.isEmpty ? 0.0 : completed / _challenges.length;

    return Scaffold(
      backgroundColor: bg,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildHeader(user),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildQuoteBanner(),
                        const SizedBox(height: 16),
                        _buildStatsRow(user, progress, completed),
                        const SizedBox(height: 20),
                        _buildSectionTitle('🔥 Thử thách hôm nay', onTap: () {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ChallengesScreen()))
                              .then((_) => _loadData());
                        }),
                        const SizedBox(height: 12),
                        ..._challenges
                            .take(3)
                            .map((c) => _buildChallengeItem(c)),
                        const SizedBox(height: 20),
                        _buildSectionTitle('📢 Bài đăng từ Admin', onTap: null),
                        const SizedBox(height: 12),
                        ..._posts.take(3).map((p) => _buildPostCard(p)),
                        const SizedBox(height: 20),
                        _buildSectionTitle('🏆 Bảng xếp hạng', onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LeaderboardScreen()));
                        }),
                        const SizedBox(height: 12),
                        _buildLeaderboardPreview(),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(UserModel user) {
    final loc = context.read<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF0F4FF),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1040), const Color(0xFF0A0E1A)]
                  : [const Color(0xFF4C1D95), const Color(0xFF1E3A5F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_getGreeting(loc)}, ${user.username.split(' ').last}! 👋',
                      style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      _formatDate(DateTime.now(), loc),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              RankBadge(rank: user.rank, points: user.points, compact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteBanner() {
    return Container(
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
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Quote ngày hôm nay',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                )),
          ]),
          const SizedBox(height: 10),
          Text(_todayQuote,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              )),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
  }

  Widget _buildStatsRow(UserModel user, double progress, int completed) {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                '🎯 Thử thách',
                '$completed/${_challenges.length}',
                progress,
                AppColors.secondary)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('⚡ Điểm', '${user.points}',
                (user.points % 500) / 500, AppColors.warning)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                '📋 Hoạt động', '${_activities.length}', 1.0, AppColors.info)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text('Xem tất cả',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildChallengeItem(ChallengeModel c) {
    final colors = {
      'fitness': AppColors.accent,
      'nutrition': AppColors.success,
      'mindset': AppColors.primary,
      'productivity': AppColors.warning
    };
    final color = colors[c.category] ?? AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: c.isCompleted
                ? AppColors.success.withValues(alpha: 0.3)
                : AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(
              c.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: c.isCompleted ? AppColors.success : color,
              size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title,
              style: TextStyle(
                  color: c.isCompleted ? AppColors.textSecondary : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration:
                      c.isCompleted ? TextDecoration.lineThrough : null)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8)),
          child: Text('+${c.points}',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              post.imageUrl!,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.adminName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ]),
            ]),
            const SizedBox(height: 12),
            Text(post.title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text(post.content,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLeaderboardPreview() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1040), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Text('🏆', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Bảng xếp hạng',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('Xem thứ hạng của bạn và các người dùng khác',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ])),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.primary, size: 16),
        ]),
      ),
    );
  }

  String _getGreeting(LocaleProvider loc) {
    final hour = DateTime.now().hour;
    if (loc.isVietnamese) {
      if (hour < 12) return 'Chào buổi sáng';
      if (hour < 18) return 'Chào buổi chiều';
      return 'Chào buổi tối';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 18) return 'Good afternoon';
      return 'Good evening';
    }
  }

  String _formatDate(DateTime d, LocaleProvider loc) {
    if (!loc.isVietnamese) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    final weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final months = [
      'tháng 1',
      'tháng 2',
      'tháng 3',
      'tháng 4',
      'tháng 5',
      'tháng 6',
      'tháng 7',
      'tháng 8',
      'tháng 9',
      'tháng 10',
      'tháng 11',
      'tháng 12'
    ];
    return '${weekdays[d.weekday - 1]}, ngày ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
