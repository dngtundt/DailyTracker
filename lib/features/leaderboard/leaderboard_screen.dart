import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/models/user_model.dart';
import '../../core/providers/locale_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  String _selectedRank = 'Tất cả';
  String _selectedCountry = 'Tất cả';
  String _selectedGender = 'Tất cả';

  List<String> get _ranks => ['Tất cả', 'Iron', 'Bronze', 'Gold', 'Platinum', 'Diamond', 'Master'];
  
  List<String> get _countries {
    final c = _allUsers.map((u) => u.country).where((e) => e != null && e.isNotEmpty).cast<String>().toSet().toList()..sort();
    return ['Tất cả', ...c];
  }

  List<String> get _genders {
    final g = _allUsers.map((u) => u.gender).where((e) => e != null && e.isNotEmpty).cast<String>().toSet().toList()..sort();
    return ['Tất cả', ...g];
  }

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    final users = await FirestoreService.instance.getAllUsers();
    final noAdmin = users.where((u) => u.role != 'admin').toList();
    if (mounted) {
      setState(() {
        _allUsers = noAdmin;
        _filtered = noAdmin;
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _allUsers.where((u) {
        final matchSearch = q.isEmpty ||
            u.username.toLowerCase().contains(q) ||
            (u.occupation?.toLowerCase().contains(q) ?? false) ||
            (u.country?.toLowerCase().contains(q) ?? false);
            
        final matchRank = _selectedRank == 'Tất cả' || u.rank.toLowerCase() == _selectedRank.toLowerCase();
        final matchCountry = _selectedCountry == 'Tất cả' || u.country == _selectedCountry;
        final matchGender = _selectedGender == 'Tất cả' || u.gender == _selectedGender;
        
        return matchSearch && matchRank && matchCountry && matchGender;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;
    final loc  = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? AppColors.background   : const Color(0xFFF0F4FF);
    final surf = isDark ? AppColors.surface       : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surf,
        title: Text(
          loc.tr('🏆 Bảng xếp hạng', '🏆 Leaderboard'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1040)),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1A1040)),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(children: [
              _buildHeader(loc, isDark, surf),
              _buildSearchBar(loc, isDark, surf),
              _buildFilters(loc, isDark, surf),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  color: AppColors.primary,
                  child: _filtered.isEmpty
                      ? Center(child: Text(loc.tr('Không tìm thấy', 'Not found'),
                          style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            // Find real global rank
                            final globalRank = _allUsers.indexOf(_filtered[i]) + 1;
                            return _buildUserRow(
                                _filtered[i], globalRank, i, currentUser?.id, isDark, loc);
                          },
                        ),
                ),
              ),
            ]),
    );
  }

  Widget _buildHeader(LocaleProvider loc, bool isDark, Color surf) {
    final myRank = _allUsers.indexWhere(
        (u) => u.id == context.read<AuthService>().currentUser?.id);
    final myUser = myRank >= 0 ? _allUsers[myRank] : null;

    if (myUser == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.getRankGradient(myUser.rank),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(
            myUser.username[0].toUpperCase(),
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
          )),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(loc.tr('Xếp hạng của bạn', 'Your Ranking'),
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(myUser.username,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('#${myRank + 1}',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28)),
          Text(loc.tr('trên ${_allUsers.length} người', 'of ${_allUsers.length} users'),
              style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ]),
      ]),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildSearchBar(LocaleProvider loc, bool isDark, Color surf) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1040)),
        decoration: InputDecoration(
          hintText: loc.tr('Tìm theo tên, nghề nghiệp, quốc gia...', 'Search by name, occupation, country...'),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () { _searchCtrl.clear(); _applyFilter(); })
              : null,
        ),
      ),
    );
  }

  Widget _buildFilters(LocaleProvider loc, bool isDark, Color surf) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildDropdown(
              label: loc.tr('Rank', 'Rank'),
              value: _selectedRank,
              items: _ranks,
              onChanged: (v) { setState(() => _selectedRank = v!); _applyFilter(); },
              isDark: isDark,
              surf: surf,
              itemLabelBuilder: (val) {
                if (val == 'Tất cả') return loc.tr('Tất cả Rank', 'All Ranks');
                final rankMap = {
                  'Iron': loc.tr('Sắt', 'Iron'),
                  'Bronze': loc.tr('Đồng', 'Bronze'),
                  'Gold': loc.tr('Vàng', 'Gold'),
                  'Platinum': loc.tr('Bạch Kim', 'Platinum'),
                  'Diamond': loc.tr('Kim Cương', 'Diamond'),
                  'Master': loc.tr('Cao Thủ', 'Master'),
                };
                return rankMap[val] ?? val;
              }
            ),
            const SizedBox(width: 8),
            _buildDropdown(
              label: loc.tr('Quốc gia', 'Country'),
              value: _selectedCountry,
              items: _countries,
              onChanged: (v) { setState(() => _selectedCountry = v!); _applyFilter(); },
              isDark: isDark,
              surf: surf,
            ),
            const SizedBox(width: 8),
            _buildDropdown(
              label: loc.tr('Giới tính', 'Gender'),
              value: _selectedGender,
              items: _genders,
              onChanged: (v) { setState(() => _selectedGender = v!); _applyFilter(); },
              isDark: isDark,
              surf: surf,
              itemLabelBuilder: (val) {
                if (val == 'Tất cả') return loc.tr('Tất cả Giới tính', 'All Genders');
                return val;
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
    required Color surf,
    String Function(String)? itemLabelBuilder,
  }) {
    final safeValue = items.contains(value) ? value : 'Tất cả';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white70 : Colors.black54),
          dropdownColor: surf,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1040), fontSize: 13, fontWeight: FontWeight.w500),
          items: items.map((e) => DropdownMenuItem(
            value: e,
            child: Text(itemLabelBuilder != null ? itemLabelBuilder(e) : e),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUserRow(UserModel user, int globalRank, int listIdx,
      String? currentUserId, bool isDark, LocaleProvider loc) {
    final isMe = user.id == currentUserId;

    Widget rankWidget;
    if (globalRank == 1) rankWidget = const Text('🥇', style: TextStyle(fontSize: 22));
    else if (globalRank == 2) rankWidget = const Text('🥈', style: TextStyle(fontSize: 22));
    else if (globalRank == 3) rankWidget = const Text('🥉', style: TextStyle(fontSize: 22));
    else rankWidget = SizedBox(width: 30, child: Text('$globalRank',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 14)));

    final cardBg = isMe
        ? AppColors.primary.withOpacity(0.1)
        : (isDark ? AppColors.surface : Colors.white);
    final cardBorder = isMe
        ? AppColors.primary.withOpacity(0.4)
        : (isDark ? AppColors.border : const Color(0xFFD1D9F0));
    final textColor = isDark ? Colors.white : const Color(0xFF1A1040);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: isMe ? 1.5 : 1),
        boxShadow: isMe ? [BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 10)] : null,
      ),
      child: Row(children: [
        SizedBox(width: 34, child: Center(child: rankWidget)),
        const SizedBox(width: 10),
        // Avatar
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: AppColors.getRankGradient(user.rank),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          )),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(user.username,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: isMe ? AppColors.primary : textColor,
                  fontWeight: FontWeight.w700, fontSize: 13))),
            if (isMe) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5)),
                child: Text(loc.tr('Bạn', 'You'),
                    style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Row(children: [
            Text(_rankLabel(user.rank, loc),
                style: TextStyle(color: _rankColor(user.rank), fontSize: 11, fontWeight: FontWeight.w600)),
            if (user.occupation != null) ...[
              const Text('  •  ', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              Flexible(child: Text(user.occupation!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
            ],
          ]),
          if (user.country != null)
            Text(user.country!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ])),
        // Points + BMI
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${user.points}',
              style: GoogleFonts.outfit(
                color: textColor, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(loc.tr('điểm', 'pts'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          if (user.bmi != null)
            Text('BMI ${user.bmi!.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _bmiColor(user.bmi!), fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: listIdx * 30)).fadeIn().slideX(begin: 0.04);
  }

  String _rankLabel(String rank, LocaleProvider loc) {
    final vi = {'iron': 'Sắt', 'bronze': 'Đồng', 'gold': 'Vàng',
                'platinum': 'Bạch Kim', 'diamond': 'Kim Cương', 'master': 'Cao Thủ'};
    final en = {'iron': 'Iron', 'bronze': 'Bronze', 'gold': 'Gold',
                'platinum': 'Platinum', 'diamond': 'Diamond', 'master': 'Master'};
    return loc.isVietnamese ? (vi[rank] ?? rank) : (en[rank] ?? rank);
  }

  Color _rankColor(String rank) {
    const map = {
      'iron': AppColors.rankIron, 'bronze': AppColors.rankBronze,
      'gold': AppColors.rankGold, 'platinum': AppColors.rankPlatinum,
      'diamond': AppColors.rankDiamond, 'master': AppColors.rankMaster,
    };
    return map[rank] ?? AppColors.textSecondary;
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25)   return AppColors.success;
    if (bmi < 30)   return AppColors.warning;
    return AppColors.error;
  }
}
