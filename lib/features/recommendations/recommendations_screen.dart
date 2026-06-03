import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/models/activity_model.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/locale_provider.dart';
import '../ai_coach/ai_chat_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc    = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.background : const Color(0xFFF0F4FF);
    final surf   = isDark ? AppColors.surface    : Colors.white;
    final border = isDark ? AppColors.border     : const Color(0xFFD1D9F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surf,
        title: Text(
          loc.tr('🔍 Khám phá', '🔍 Explore'),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700, fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1A1040),
          ),
        ),
        actions: [
          // Chat with AI button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
              ),
              tooltip: loc.tr('Chat với AI', 'Chat with AI'),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: [
            Tab(text: loc.tr('🏋️ Tập luyện', '🏋️ Workout')),
            Tab(text: loc.tr('🥗 Dinh dưỡng', '🥗 Nutrition')),
            Tab(text: loc.tr('🧘 Tinh thần', '🧘 Mindset')),
            Tab(text: loc.tr('📅 Lịch trình', '📅 Schedule')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _AiRecommendTab(category: 'workout', isDark: isDark, border: border),
          _AiRecommendTab(category: 'nutrition', isDark: isDark, border: border),
          _AiRecommendTab(category: 'mindset', isDark: isDark, border: border),
          _AiRecommendTab(category: 'schedule', isDark: isDark, border: border),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.chat_rounded, color: Colors.white),
        label: Text(
          loc.tr('Chat AI', 'Chat AI'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _AiRecommendTab extends StatefulWidget {
  final String category;
  final bool isDark;
  final Color border;

  const _AiRecommendTab({
    required this.category,
    required this.isDark,
    required this.border,
  });

  @override
  State<_AiRecommendTab> createState() => _AiRecommendTabState();
}

class _AiRecommendTabState extends State<_AiRecommendTab>
    with AutomaticKeepAliveClientMixin {
  String? _advice;
  bool _loading = false;
  UserModel? _user;
  List<ActivityModel> _activities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    if (user == null) { setState(() => _loading = false); return; }
    final recent = await FirestoreService.instance.getRecentActivities(user.id!, days: 7);
    final loc    = context.read<LocaleProvider>();
    final advice = await AiService.instance.getExploreRecommendations(
      user: user,
      recentActivities: recent,
      category: widget.category,
      isVietnamese: loc.isVietnamese,
      forceRefresh: force,
    );
    if (mounted) {
      setState(() {
        _user = user;
        _activities = recent;
        _advice = advice;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final loc    = context.watch<LocaleProvider>();
    final isDark = widget.isDark;
    final bg     = isDark ? AppColors.background : const Color(0xFFF0F4FF);

    if (_loading) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          const SizedBox(height: 16),
          Text(loc.tr('Gemini AI đang phân tích...', 'Gemini AI analyzing...'),
              style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(loc, isDark),
          const SizedBox(height: 16),
          _buildAdviceCard(loc, isDark),
          const SizedBox(height: 16),
          _buildStatCard(loc, isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfileCard(LocaleProvider loc, bool isDark) {
    if (_user == null) return const SizedBox();
    final textColor = isDark ? Colors.white : const Color(0xFF1A1040);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.getRankGradient(_user!.rank),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(_user!.username[0].toUpperCase(),
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_user!.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (_user!.bmi != null)
            Text('BMI ${_user!.bmi!.toStringAsFixed(1)} • ${_user!.bmiLabel}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (_user!.occupation != null)
            Text(_user!.occupation!, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(loc.tr('Cá nhân hóa', 'Personalized'),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildAdviceCard(LocaleProvider loc, bool isDark) {
    if (_advice == null) return const SizedBox();
    final surf   = isDark ? AppColors.surface : Colors.white;
    final border = isDark ? AppColors.border  : const Color(0xFFD1D9F0);
    final textColor = isDark ? const Color(0xFFCDD5E0) : const Color(0xFF374151);

    final catIcons = {
      'workout': Icons.fitness_center_rounded,
      'nutrition': Icons.restaurant_rounded,
      'mindset': Icons.self_improvement_rounded,
      'schedule': Icons.calendar_today_rounded,
    };
    final catTitles = {
      'workout':   loc.tr('Kế hoạch tập luyện', 'Workout Plan'),
      'nutrition': loc.tr('Dinh dưỡng', 'Nutrition'),
      'mindset':   loc.tr('Sức khỏe tinh thần', 'Mental Health'),
      'schedule':  loc.tr('Tối ưu lịch trình', 'Schedule Optimize'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(catIcons[widget.category] ?? Icons.auto_awesome_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(catTitles[widget.category] ?? '',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : const Color(0xFF1A1040),
                fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('AI', style: TextStyle(
              color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        Divider(color: border),
        const SizedBox(height: 8),
        Text(_advice!, style: TextStyle(color: textColor, fontSize: 14, height: 1.7)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _load(force: true),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(loc.tr('Tạo lại', 'Refresh'), style: const TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
        ),
      ]),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildStatCard(LocaleProvider loc, bool isDark) {
    if (_activities.isEmpty) return const SizedBox();
    final surf   = isDark ? AppColors.surface : Colors.white;
    final border = isDark ? AppColors.border  : const Color(0xFFD1D9F0);

    final sportN = _activities.where((a) => a.category == 'sport').length;
    final foodN  = _activities.where((a) => a.category == 'food').length;
    final workN  = _activities.where((a) => a.category == 'work').length;
    final restN  = _activities.where((a) => a.category == 'rest').length;
    final total  = _activities.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.tr('📊 Thống kê 7 ngày qua', '📊 Last 7 Days Stats'),
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : const Color(0xFF1A1040),
              fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        _statBar(loc.tr('Thể thao', 'Sport'), sportN, total, AppColors.accent, isDark),
        _statBar(loc.tr('Ăn uống', 'Food'),   foodN,  total, AppColors.success, isDark),
        _statBar(loc.tr('Công việc', 'Work'),  workN,  total, AppColors.primary, isDark),
        _statBar(loc.tr('Nghỉ ngơi', 'Rest'),  restN,  total, AppColors.secondary, isDark),
      ]),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _statBar(String label, int val, int total, Color color, bool isDark) {
    final pct = total == 0 ? 0.0 : val / total;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1040);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(width: 72, child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        )),
        const SizedBox(width: 8),
        Text('$val', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
