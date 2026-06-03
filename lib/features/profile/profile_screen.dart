import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../widgets/rank_badge.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../auth/login_screen.dart';
import '../../core/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final loc = context.watch<LocaleProvider>();
    final thm = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox();

    final isIncomplete = user.gender == null || user.gender!.trim().isEmpty ||
        user.age == null || user.age! <= 0 ||
        user.heightCm == null || user.heightCm! <= 0 ||
        user.weightKg == null || user.weightKg! <= 0 ||
        user.country == null || user.country!.trim().isEmpty;

    if (isIncomplete && user.role != 'admin') {
      return _CompleteProfileForm(user: user);
    }

    final rankProgress = _getRankProgress(user.points, user.rank);
    final bg = isDark ? AppColors.background : const Color(0xFFF0F4FF);
    final surf = isDark ? AppColors.surface : Colors.white;
    final bord = isDark ? AppColors.border : const Color(0xFFD1D9F0);
    final textH = isDark ? Colors.white : const Color(0xFF1A1040);
    final textS = isDark ? AppColors.textSecondary : const Color(0xFF5A6584);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: surf,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.getRankGradient(user.rank),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                          child: Text(
                        user.username.isNotEmpty
                            ? user.username[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 36),
                      )),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 12),
                    Text(user.username,
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20)),
                    Text(user.email,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    if (user.occupation != null || user.country != null)
                      Text(
                        [
                          if (user.occupation != null) user.occupation!,
                          if (user.country != null) user.country!
                        ].join(' • '),
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Rank progress card
                _buildRankCard(
                    user, rankProgress, surf, bord, textH, textS, loc),
                const SizedBox(height: 16),

                // Stats row
                _buildStatsRow(user, surf, bord, textH, textS, loc),
                const SizedBox(height: 16),

                // Body stats (BMI, height, weight)
                _buildBodyCard(context, user, surf, bord, textH, textS, loc),
                const SizedBox(height: 16),

                // ── SETTINGS SECTION ──────────────────────────────────
                _sectionTitle(loc.tr('⚙️ Cài đặt', '⚙️ Settings'), textH),
                const SizedBox(height: 8),

                // Theme toggle
                _settingsTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: isDark ? AppColors.primary : AppColors.warning,
                  title: loc.tr('Giao diện', 'Theme'),
                  subtitle:
                      isDark ? loc.tr('Tối', 'Dark') : loc.tr('Sáng', 'Light'),
                  trailing: Switch.adaptive(
                    value: isDark,
                    onChanged: (_) =>
                        context.read<ThemeProvider>().toggleTheme(),
                    activeColor: AppColors.primary,
                  ),
                  surf: surf,
                  bord: bord,
                  textH: textH,
                  textS: textS,
                ),
                const SizedBox(height: 8),

                // Language toggle
                _settingsTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.secondary,
                  title: loc.tr('Ngôn ngữ', 'Language'),
                  subtitle:
                      loc.isVietnamese ? '🇻🇳 Tiếng Việt' : '🇺🇸 English',
                  trailing: GestureDetector(
                    onTap: () => context.read<LocaleProvider>().toggleLocale(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        loc.isVietnamese ? 'VI' : 'EN',
                        style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  surf: surf,
                  bord: bord,
                  textH: textH,
                  textS: textS,
                ),
                const SizedBox(height: 16),

                // ── MENU SECTION ──────────────────────────────────────
                _sectionTitle(loc.tr('📋 Menu', '📋 Menu'), textH),
                const SizedBox(height: 8),

                _menuTile(
                  context: context,
                  surf: surf,
                  bord: bord,
                  textH: textH,
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.rankGold,
                  label: loc.tr('Bảng xếp hạng', 'Leaderboard'),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LeaderboardScreen())),
                ),
                const SizedBox(height: 8),
                _menuTile(
                  context: context,
                  surf: surf,
                  bord: bord,
                  textH: textH,
                  icon: Icons.notifications_outlined,
                  color: AppColors.warning,
                  label: loc.tr('Cài đặt thông báo', 'Notification Settings'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(loc.tr('Sắp ra mắt!', 'Coming soon!'))),
                  ),
                ),
                const SizedBox(height: 8),
                _menuTile(
                  context: context,
                  surf: surf,
                  bord: bord,
                  textH: textH,
                  icon: Icons.info_outline_rounded,
                  color: AppColors.info,
                  label: loc.tr('Về ứng dụng', 'About App'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'DailyTracker',
                    applicationVersion: '1.0.0',
                    applicationLegalese: loc.tr(
                        'Xây dựng thói quen tốt mỗi ngày',
                        'Build better habits every day'),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: Text(
                      loc.tr('Đăng xuất', 'Logout'),
                      style: const TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 0),
        child: Text(title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      );

  Widget _buildRankCard(user, Map<String, dynamic> rp, Color surf, Color bord,
      Color textH, Color textS, LocaleProvider loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bord),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          RankBadge(rank: user.rank, points: user.points),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${user.points} ${loc.tr('điểm', 'pts')}',
                style: GoogleFonts.outfit(
                    color: textH, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(loc.tr('Tổng điểm tích lũy', 'Total points earned'),
                style: TextStyle(color: textS, fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
                loc.tr('Tiến độ lên ${rp['nextRank']}',
                    'Progress to ${rp['nextRank']}'),
                style: TextStyle(color: textS, fontSize: 12)),
            Text('${rp['current']}/${rp['needed']}',
                style: TextStyle(
                    color: textH, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rp['progress'] as double).clamp(0.0, 1.0),
              backgroundColor: bord,
              valueColor: AlwaysStoppedAnimation(
                  AppColors.getRankGradient(user.rank).colors.first),
              minHeight: 8,
            ),
          ),
        ]),
      ]),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildStatsRow(user, Color surf, Color bord, Color textH, Color textS,
      LocaleProvider loc) {
    return Row(children: [
      Expanded(
          child: _statCard('🏆', loc.tr('Hạng', 'Rank'),
              _getRankName(user.rank, loc), surf, bord, textH, textS)),
      const SizedBox(width: 12),
      Expanded(
          child: _statCard('⚡', loc.tr('Điểm', 'Points'), '${user.points}',
              surf, bord, textH, textS)),
      const SizedBox(width: 12),
      Expanded(
          child: _statCard(
              '🎯',
              'Role',
              user.role == 'admin' ? 'Admin' : 'User',
              surf,
              bord,
              textH,
              textS)),
    ]);
  }

  Widget _buildBodyCard(BuildContext context, user, Color surf, Color bord,
      Color textH, Color textS, LocaleProvider loc) {
    final bmi = user.bmi;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bord),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(loc.tr('💪 Thể trạng', '💪 Body Stats'),
            style: TextStyle(
                color: textH, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showBodyStatsEditor(context, user),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(loc.tr('Chỉnh sửa', 'Edit')),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (user.heightCm == null && user.weightKg == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: const Text(
              'Bạn chưa cập nhật chiều cao và cân nặng. Hãy bấm "Chỉnh sửa" để thêm thể trạng hiện tại.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ] else
          Row(children: [
            if (user.heightCm != null)
              Expanded(
                  child: _statCard(
                      '📏',
                      loc.tr('Chiều cao', 'Height'),
                      '${user.heightCm!.toStringAsFixed(0)} cm',
                      surf,
                      bord,
                      textH,
                      textS)),
            if (user.heightCm != null) const SizedBox(width: 10),
            if (user.weightKg != null)
              Expanded(
                  child: _statCard(
                      '⚖️',
                      loc.tr('Cân nặng', 'Weight'),
                      '${user.weightKg!.toStringAsFixed(1)} kg',
                      surf,
                      bord,
                      textH,
                      textS)),
            if (user.weightKg != null && bmi != null) const SizedBox(width: 10),
            if (bmi != null)
              Expanded(
                  child: _statCard('🔢', 'BMI', bmi.toStringAsFixed(1), surf,
                      bord, _bmiColor(bmi), textS)),
          ]),
        if (bmi != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _bmiColor(bmi).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(user.bmiLabel,
                style: TextStyle(
                    color: _bmiColor(bmi),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ]),
    );
  }

  Future<void> _showBodyStatsEditor(BuildContext context, user) async {
    var draftHeight = user.heightCm?.toStringAsFixed(0) ?? '';
    var draftWeight = user.weightKg?.toStringAsFixed(1) ?? '';
    var isClosingDialog = false;
    final formKey = GlobalKey<FormState>();

    final submittedValues = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'C\u1eadp nh\u1eadt th\u1ec3 tr\u1ea1ng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: draftHeight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Chi\u1ec1u cao (cm)',
                  prefixIcon: Icon(Icons.height_rounded),
                ),
                onChanged: (value) => draftHeight = value,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Nh\u1eadp chi\u1ec1u cao h\u1ee3p l\u1ec7';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: draftWeight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'C\u00e2n n\u1eb7ng (kg)',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
                onChanged: (value) => draftWeight = value,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Nh\u1eadp c\u00e2n n\u1eb7ng h\u1ee3p l\u1ec7';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (isClosingDialog) return;
              isClosingDialog = true;
              Navigator.of(dialogContext).pop();
            },
            child: const Text(
              'H\u1ee7y',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (isClosingDialog) return;
              if (!formKey.currentState!.validate()) return;
              
              isClosingDialog = true;
              final result = <String, String>{
                'heightCm': draftHeight.trim(),
                'weightKg': draftWeight.trim(),
              };
              Navigator.of(dialogContext).pop(result);
            },
            child: const Text('L\u01b0u'),
          ),
        ],
      ),
    );

    if (submittedValues == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final err = await context.read<AuthService>().updateBodyStats(
          heightCm: double.parse(submittedValues['heightCm']!),
          weightKg: double.parse(submittedValues['weightKg']!),
        );
    if (!context.mounted) return;

    if (err != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          '\u0110\u00e3 c\u1eadp nh\u1eadt chi\u1ec1u cao v\u00e0 c\u00e2n n\u1eb7ng',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    await context.read<AuthService>().refreshUser();
  }

  Widget _statCard(String icon, String label, String value, Color surf,
      Color bord, Color textH, Color textS) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bord),
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                color: textH, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: TextStyle(color: textS, fontSize: 10)),
      ]),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color surf,
    required Color bord,
    required Color textH,
    required Color textS,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bord),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  color: textH, fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: TextStyle(color: textS, fontSize: 12)),
        ])),
        trailing,
      ]),
    );
  }

  Widget _menuTile({
    required BuildContext context,
    required Color surf,
    required Color bord,
    required Color textH,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bord),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: textH, fontWeight: FontWeight.w500))),
          Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted, size: 14),
        ]),
      ),
    );
  }

  Map<String, dynamic> _getRankProgress(int points, String rank) {
    final thresholds = {
      'iron': 500,
      'bronze': 1500,
      'gold': 4000,
      'platinum': 8000,
      'diamond': 15000,
      'master': 15000
    };
    final names = {
      'iron': 'Đồng',
      'bronze': 'Vàng',
      'gold': 'Bạch Kim',
      'platinum': 'Kim Cương',
      'diamond': 'Cao Thủ',
      'master': 'Max'
    };
    final starts = {
      'iron': 0,
      'bronze': 500,
      'gold': 1500,
      'platinum': 4000,
      'diamond': 8000,
      'master': 15000
    };

    final needed = thresholds[rank] ?? 15000;
    final start = starts[rank] ?? 0;
    final current = points - start;
    final range = needed - start;
    final progress = range == 0 ? 1.0 : (current / range).clamp(0.0, 1.0);

    return {
      'nextRank': names[rank] ?? 'Max',
      'current': current,
      'needed': range,
      'progress': progress
    };
  }

  String _getRankName(String rank, LocaleProvider loc) {
    if (!loc.isVietnamese) {
      const en = {
        'iron': 'Iron',
        'bronze': 'Bronze',
        'gold': 'Gold',
        'platinum': 'Platinum',
        'diamond': 'Diamond',
        'master': 'Master'
      };
      return en[rank] ?? rank;
    }
    const vi = {
      'iron': 'Sắt',
      'bronze': 'Đồng',
      'gold': 'Vàng',
      'platinum': 'Bạch Kim',
      'diamond': 'Kim Cương',
      'master': 'Cao Thủ'
    };
    return vi[rank] ?? rank;
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25) return AppColors.success;
    if (bmi < 30) return AppColors.warning;
    return AppColors.error;
  }
}

class _CompleteProfileForm extends StatefulWidget {
  final UserModel user;
  const _CompleteProfileForm({required this.user});

  @override
  State<_CompleteProfileForm> createState() => _CompleteProfileFormState();
}

class _CompleteProfileFormState extends State<_CompleteProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _gender;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late String _country;
  late final TextEditingController _occupCtrl;

  bool _loading = false;
  String? _error;

  static const List<String> _countries = [
    'Việt Nam', 'Mỹ', 'Nhật Bản', 'Hàn Quốc', 'Trung Quốc',
    'Đức', 'Pháp', 'Anh', 'Úc', 'Canada', 'Singapore',
    'Thái Lan', 'Malaysia', 'Indonesia', 'Philippines', 'Khác',
  ];

  @override
  void initState() {
    super.initState();
    _gender = widget.user.gender ?? 'Nam';
    _ageCtrl = TextEditingController(text: widget.user.age?.toString() ?? '');
    _heightCtrl = TextEditingController(text: widget.user.heightCm?.toStringAsFixed(0) ?? '');
    _weightCtrl = TextEditingController(text: widget.user.weightKg?.toStringAsFixed(1) ?? '');
    _country = widget.user.country ?? 'Việt Nam';
    if (!_countries.contains(_country)) {
      _country = 'Việt Nam';
    }
    _occupCtrl = TextEditingController(text: widget.user.occupation ?? '');
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _occupCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final age = int.tryParse(_ageCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);

    if (age == null || height == null || weight == null) {
      setState(() {
        _loading = false;
        _error = 'Vui lòng nhập số hợp lệ';
      });
      return;
    }

    final err = await context.read<AuthService>().updateProfile(
      gender: _gender,
      age: age,
      heightCm: height,
      weightKg: weight,
      country: _country,
      occupation: _occupCtrl.text.trim().isNotEmpty ? _occupCtrl.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _error = err);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã cập nhật hồ sơ thành công!'), backgroundColor: AppColors.success),
      );
      await context.read<AuthService>().refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surf = isDark ? AppColors.surface : Colors.white;
    final bord = isDark ? AppColors.border : const Color(0xFFD1D9F0);
    final textH = isDark ? Colors.white : const Color(0xFF1A1040);
    final textS = isDark ? AppColors.textSecondary : const Color(0xFF5A6584);

    return Scaffold(
      backgroundColor: isDark ? AppColors.background : const Color(0xFFF0F4FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_rounded,
                    color: AppColors.warning,
                    size: 48,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
                Text(
                  'YÊU CẦU CẬP NHẬT',
                  style: GoogleFonts.outfit(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hoàn thiện Hồ sơ',
                  style: GoogleFonts.outfit(
                    color: textH,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Để bảo mật và tối ưu hóa trải nghiệm cá nhân, vui lòng nhập đầy đủ thông tin để truy cập trang cá nhân.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textS,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surf,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: bord),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Giới tính *', style: TextStyle(color: textS, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: ['Nam', 'Nữ', 'Khác'].map((g) {
                          final sel = _gender == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _gender = g),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: sel ? AppColors.primaryGradient : null,
                                  color: sel ? null : (isDark ? AppColors.surfaceVariant : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? Colors.transparent : bord,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      color: sel ? Colors.white : textS,
                                      fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _ageCtrl,
                              label: 'Tuổi *',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final val = int.tryParse(value ?? '');
                                if (val == null || val <= 0 || val > 120) {
                                  return 'Nhập tuổi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              controller: _heightCtrl,
                              label: 'Cao (cm) *',
                              icon: Icons.height_rounded,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final val = double.tryParse(value ?? '');
                                if (val == null || val < 50 || val > 250) {
                                  return 'Nhập chiều cao';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              controller: _weightCtrl,
                              label: 'Nặng (kg) *',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                final val = double.tryParse(value ?? '');
                                if (val == null || val < 10 || val > 300) {
                                  return 'Nhập cân nặng';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Quốc gia *', style: TextStyle(color: textS, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _country,
                        dropdownColor: surf,
                        style: TextStyle(color: textH),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: bord),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.error),
                          ),
                        ),
                        items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _country = v!),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _occupCtrl,
                        label: 'Nghề nghiệp (Tùy chọn)',
                        icon: Icons.work_outline_rounded,
                        keyboardType: TextInputType.text,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Lưu & Tiếp tục'),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textH = isDark ? Colors.white : const Color(0xFF1A1040);
    final textS = isDark ? AppColors.textSecondary : const Color(0xFF5A6584);
    final bord = isDark ? AppColors.border : const Color(0xFFD1D9F0);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textH, fontSize: 13),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textS, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: bord),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        errorStyle: const TextStyle(fontSize: 10),
      ),
    );
  }
}
