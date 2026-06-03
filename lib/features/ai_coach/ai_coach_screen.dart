import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/models/activity_model.dart';
import '../../core/providers/locale_provider.dart';
import 'ai_chat_screen.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  String? _advice;
  bool _loading = false;
  List<ActivityModel> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchAdvice();
  }

  Future<void> _fetchAdvice({bool force = false}) async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final loc    = context.read<LocaleProvider>();
    final recent = await FirestoreService.instance.getRecentActivities(user.id!, days: 7);
    final advice = await AiService.instance.getPersonalizedPlan(
      user: user,
      recentActivities: recent,
      targetDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      forceRefresh: force,
    );
    if (mounted) {
      setState(() {
        _advice = advice;
        _recentActivities = recent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user   = context.watch<AuthService>().currentUser;
    final loc    = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surf   = isDark ? AppColors.surface : Colors.white;
    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: surf,
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Text(loc.tr('AI Life Coach', 'AI Life Coach'),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1040))),
        ]),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
            ),
            tooltip: loc.tr('Chat với AI', 'Chat with AI'),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AiChatScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : () => _fetchAdvice(force: true),
            tooltip: loc.tr('Cập nhật', 'Refresh'),
          ),
        ],
      ),
      body: _loading ? _buildLoadingState(loc) : _buildContent(user?.username ?? '', loc, isDark),
    );
  }

  Widget _buildLoadingState(LocaleProvider loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20)],
            ),
            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms),
          const SizedBox(height: 24),
          Text(loc.tr('Gemini AI đang phân tích...', 'Gemini AI analyzing...'),
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(loc.tr('Đang đọc lịch sử 7 ngày của bạn', 'Reading your 7-day history...'),
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          SizedBox(width: 200, child: LinearProgressIndicator(
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          )),
        ],
      ),
    );
  }

  Widget _buildContent(String username, LocaleProvider loc, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _buildAiHeader(username, loc),
        const SizedBox(height: 16),
        _buildStatsRow(loc, isDark),
        const SizedBox(height: 16),
        _buildAdviceCard(loc, isDark),
        const SizedBox(height: 16),
        _buildRecentActivitySummary(loc, isDark),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildAiHeader(String username, LocaleProvider loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF4C1D95).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gemini AI Coach', style: GoogleFonts.outfit(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18,
          )),
          Text(
            loc.tr('Kế hoạch cá nhân hóa cho $username', 'Personalized plan for $username'),
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w700)),
        ),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatsRow(LocaleProvider loc, bool isDark) {
    final sportDays = _recentActivities.where((a) => a.category == 'sport').length;
    final foodLogs  = _recentActivities.where((a) => a.category == 'food').length;
    final donePct   = _recentActivities.isEmpty ? 0
        : (_recentActivities.where((a) => a.isDone).length * 100 ~/ _recentActivities.length);
    final surf = isDark ? AppColors.surface : Colors.white;
    return Row(children: [
      Expanded(child: _miniStat('🏃', '$sportDays', loc.tr('Thể thao', 'Sport'), AppColors.accent, surf)),
      const SizedBox(width: 10),
      Expanded(child: _miniStat('🥗', '$foodLogs', loc.tr('Bữa ăn', 'Food logs'), AppColors.success, surf)),
      const SizedBox(width: 10),
      Expanded(child: _miniStat('✅', '$donePct%', loc.tr('Hoàn thành', 'Done'), AppColors.primary, surf)),
    ]);
  }

  Widget _miniStat(String icon, String value, String label, Color color, Color surf) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ]),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildAdviceCard(LocaleProvider loc, bool isDark) {
    if (_advice == null) return const SizedBox();
    final surf = isDark ? AppColors.surface : Colors.white;
    final bord = isDark ? AppColors.border  : const Color(0xFFD1D9F0);
    final txtH = isDark ? Colors.white : const Color(0xFF1A1040);
    final txtB = isDark ? const Color(0xFFCDD5E0) : const Color(0xFF374151);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bord),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(loc.tr('Kế hoạch hôm nay', 'Today\'s Plan'),
              style: GoogleFonts.outfit(color: txtH, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(loc.tr('Cá nhân hóa', 'Personalized'),
                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        Divider(color: bord, height: 24),
        Text(_advice!, style: TextStyle(color: txtB, fontSize: 14, height: 1.8)),
      ]),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildRecentActivitySummary(LocaleProvider loc, bool isDark) {
    if (_recentActivities.isEmpty) return const SizedBox();

    final byDate = <String, int>{};
    for (final a in _recentActivities) {
      final key = a.date.toIso8601String().substring(0, 10);
      byDate[key] = (byDate[key] ?? 0) + 1;
    }
    final entries = byDate.entries.take(5).toList();
    final surf  = isDark ? AppColors.surface : Colors.white;
    final bord  = isDark ? AppColors.border  : const Color(0xFFD1D9F0);
    final txtH  = isDark ? Colors.white : const Color(0xFF1A1040);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bord),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          loc.tr('📈 Hoạt động 7 ngày qua', '📈 Last 7 Days Activity'),
          style: GoogleFonts.outfit(color: txtH, fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 14),
        ...entries.map((e) {
          final pct = e.value / 10.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(e.key.substring(5),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(width: 10),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: bord,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 8,
                ),
              )),
              const SizedBox(width: 8),
              Text('${e.value}', style: TextStyle(color: txtH, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ]),
    ).animate().fadeIn(delay: 400.ms);
  }
}

