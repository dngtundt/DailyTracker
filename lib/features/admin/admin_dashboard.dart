import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/post_model.dart';
import '../../core/models/user_model.dart';
import '../../core/models/challenge_model.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import 'admin_challenge_screen.dart';
import 'admin_post_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<PostModel> _posts = [];
  List<UserModel> _users = [];
  List<ChallengeModel> _challenges = [];
  bool _loading = true;
  int _selectedSegment = 0; // 0: Người dùng, 1: Bài đăng, 2: Thử thách
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    
    try {
      final posts = await FirestoreService.instance.getAllPosts();
      final users = await FirestoreService.instance.getAllUsers();
      final challenges = await FirestoreService.instance.getAllChallenges();
      if (mounted) {
        setState(() {
          _posts = posts;
          _users = users.where((u) => u.role != 'admin').toList();
          _challenges = challenges;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deletePost(String id) async {
    try {
      await FirestoreService.instance.deletePost(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa bài đăng thành công'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa bài đăng: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      final query = _searchQuery.toLowerCase().trim();
      return u.username.toLowerCase().contains(query) ||
          u.email.toLowerCase().contains(query) ||
          (u.country?.toLowerCase().contains(query) ?? false);
    }).toList();

    final filteredPosts = _posts.where((p) {
      final query = _searchQuery.toLowerCase().trim();
      return p.title.toLowerCase().contains(query) ||
          p.content.toLowerCase().contains(query);
    }).toList();

    final filteredChallenges = _challenges.where((c) {
      final query = _searchQuery.toLowerCase().trim();
      return c.title.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.startDate.toLowerCase().contains(query) ||
          c.endDate.toLowerCase().contains(query) ||
          c.category.toLowerCase().contains(query);
    }).toList();

    // Paginate users
    final totalPages = (filteredUsers.length / _pageSize).ceil();
    if (totalPages == 0) {
      _currentPage = 1;
    } else if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 20.0, bottom: 20.0, right: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'QUẢN TRỊ VIÊN',
                                style: GoogleFonts.outfit(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hệ thống Quản lý',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                  onPressed: _loadData,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                                  onPressed: () async {
                                    await context.read<AuthService>().logout();
                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (_) => false,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Overview Row
                      _buildStatsRow(),
                      const SizedBox(height: 20),

                      // Quick Action panel (Tạo bài đăng & Tạo thử thách)
                      Text(
                        '⚡ Công cụ Quản lý',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Tab selector
                      _buildSegmentedControl(),
                      const SizedBox(height: 16),

                      // Segment Content
                      if (_selectedSegment == 0) ...[
                        _buildSearchBar('Tìm thành viên theo tên, email, quốc gia...'),
                        const SizedBox(height: 12),
                        _buildUsersTable(paginatedUsers),
                        _buildPaginationRow(filteredUsers.length),
                      ] else if (_selectedSegment == 1) ...[
                        _buildSearchBar('Tìm bài đăng theo tiêu đề, nội dung...'),
                        const SizedBox(height: 12),
                        if (filteredPosts.isEmpty)
                          _buildEmptyState('Không tìm thấy bài đăng nào phù hợp.')
                        else
                          ...filteredPosts.map((p) => _buildPostCard(p)),
                      ] else ...[
                        _buildSearchBar('Tìm thử thách theo tiêu đề, mô tả...'),
                        const SizedBox(height: 12),
                        if (filteredChallenges.isEmpty)
                          _buildEmptyState('Không tìm thấy thử thách nào phù hợp.')
                        else
                          ...filteredChallenges.map((c) => _buildChallengeCard(c)),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalPoints = _users.fold(0, (sum, u) => sum + u.points);
    return Row(
      children: [
        Expanded(child: _statCard('👥', 'Thành viên', '${_users.length}', AppColors.info)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('📢', 'Bài viết', '${_posts.length}', AppColors.secondary)),
        const SizedBox(width: 8),
        Expanded(child: _statCard('⚡', 'Tổng điểm', '$totalPoints', AppColors.warning)),
      ],
    );
  }

  Widget _statCard(String icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: 'Đăng bài viết',
            subtitle: 'Đăng thông báo, lời khuyên và chọn lọc người nhận.',
            icon: Icons.add_photo_alternate_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminPostScreen()),
            ).then((_) => _loadData()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionCard(
            title: 'Tạo thử thách',
            subtitle: 'Tạo thử thách hằng ngày và phân nhóm đối tượng nhận.',
            icon: Icons.emoji_events_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminChallengeScreen()),
            ).then((_) => _loadData()),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 140,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 300.ms);
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(0, '👥 Thành viên'),
          ),
          Expanded(
            child: _segmentButton(1, '📢 Bài viết'),
          ),
          Expanded(
            child: _segmentButton(2, '🏆 Thử thách'),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(int index, String label) {
    final active = _selectedSegment == index;
    return GestureDetector(
      onTap: () {
        _searchCtrl.clear();
        setState(() {
          _selectedSegment = index;
          _searchQuery = '';
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildUsersTable(List<UserModel> filteredUsers) {
    if (filteredUsers.isEmpty) {
      return _buildEmptyState('Không tìm thấy người dùng nào phù hợp.');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Người dùng',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Hạng',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Điểm',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ...filteredUsers.asMap().entries.map((entry) {
            final i = entry.key;
            final user = entry.value;
            final rankColors = {
              'iron': AppColors.rankIron,
              'bronze': AppColors.rankBronze,
              'gold': AppColors.rankGold,
              'platinum': AppColors.rankPlatinum,
              'diamond': AppColors.rankDiamond,
              'master': AppColors.rankMaster,
            };
            final rankColor = rankColors[user.rank] ?? AppColors.textSecondary;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == filteredUsers.length - 1 ? Colors.transparent : AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppColors.getRankGradient(user.rank),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.email,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _getRankViName(user.rank),
                      style: TextStyle(color: rankColor, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${user.points}',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title,
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 10),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: AppColors.textSecondary.withOpacity(0.5),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.viewedUserIds.length} người xem',
                                style: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminPostScreen(post: post)),
                          ).then((_) => _loadData()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => _showDeleteDialog(post),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.content,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                if (post.targetCountries.isNotEmpty ||
                    post.targetRanks.isNotEmpty ||
                    post.targetGenders.isNotEmpty ||
                    post.targetBmiLevels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF2A3650), height: 1),
                  const SizedBox(height: 8),
                  _buildPostTargetsPreview(post),
                ]
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildPostTargetsPreview(PostModel post) {
    final targets = <String>[
      if (post.targetCountries.isNotEmpty) '🌍 ${post.targetCountries.join(', ')}',
      if (post.targetRanks.isNotEmpty) '🏆 ${post.targetRanks.map(_getRankViName).join(', ')}',
      if (post.targetGenders.isNotEmpty) '🚻 ${post.targetGenders.join(', ')}',
      if (post.targetBmiLevels.isNotEmpty) '⚖️ ${post.targetBmiLevels.map(_getBmiViName).join(', ')}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: targets.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      )).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_rounded, color: AppColors.textSecondary, size: 40),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(PostModel post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa bài đăng?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa bài "${post.title}" không?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(post.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _getRankViName(String rank) {
    const map = {
      'iron': 'Sắt',
      'bronze': 'Đồng',
      'gold': 'Vàng',
      'platinum': 'Bạch Kim',
      'diamond': 'Kim Cương',
      'master': 'Cao Thủ',
    };
    return map[rank] ?? rank;
  }

  String _getBmiViName(String bmi) {
    const map = {
      'underweight': 'Thiếu cân',
      'normal': 'Bình thường',
      'overweight': 'Thừa cân',
      'obese': 'Béo phì',
    };
    return map[bmi] ?? bmi;
  }

  Widget _buildChallengeCard(ChallengeModel challenge) {
    final categoryColors = {
      'fitness': Colors.green,
      'nutrition': Colors.orange,
      'mindset': Colors.purple,
      'productivity': Colors.blue,
    };
    final color = categoryColors[challenge.category] ?? AppColors.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                challenge.startDate == challenge.endDate
                                    ? 'Áp dụng ngày: ${challenge.startDate}'
                                    : 'Áp dụng: từ ${challenge.startDate} đến ${challenge.endDate}',
                                style: TextStyle(
                                  color: color.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                '⚡ ${challenge.points}đ',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              FutureBuilder<int>(
                                future: FirestoreService.instance.getChallengeCompletionCount(challenge.id ?? ''),
                                builder: (context, snapshot) {
                                  final count = snapshot.data ?? 0;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: color, size: 12),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$count đã hoàn thành',
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminChallengeScreen(challenge: challenge)),
                          ).then((_) => _loadData()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => _showDeleteChallengeDialog(challenge),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                if (challenge.targetCountries.isNotEmpty ||
                    challenge.targetRanks.isNotEmpty ||
                    challenge.targetGenders.isNotEmpty ||
                    challenge.targetBmiLevels.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF2A3650), height: 1),
                  const SizedBox(height: 8),
                  _buildChallengeTargetsPreview(challenge),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeTargetsPreview(ChallengeModel challenge) {
    final targets = <String>[
      if (challenge.targetCountries.isNotEmpty) '🌍 ${challenge.targetCountries.join(', ')}',
      if (challenge.targetRanks.isNotEmpty) '🏆 ${challenge.targetRanks.map(_getRankViName).join(', ')}',
      if (challenge.targetGenders.isNotEmpty) '🚻 ${challenge.targetGenders.join(', ')}',
      if (challenge.targetBmiLevels.isNotEmpty) '⚖️ ${challenge.targetBmiLevels.map(_getBmiViName).join(', ')}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: targets.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      )).toList(),
    );
  }

  Future<void> _deleteChallenge(String id) async {
    try {
      await FirestoreService.instance.deleteChallenge(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Đã xóa thử thách thành công'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa thử thách: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showDeleteChallengeDialog(ChallengeModel challenge) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thử thách?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa thử thách "${challenge.title}" không?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChallenge(challenge.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationRow(int totalItems) {
    final totalPages = (totalItems / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _currentPage > 1
                  ? () => setState(() => _currentPage--)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentPage > 1
                      ? AppColors.surfaceVariant
                      : AppColors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentPage > 1
                        ? AppColors.border
                        : AppColors.border.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: _currentPage > 1 ? Colors.white : Colors.white24,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages, (index) {
              final pageNum = index + 1;
              final isCurrent = pageNum == _currentPage;
              return GestureDetector(
                onTap: () => setState(() => _currentPage = pageNum),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : AppColors.border,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$pageNum',
                      style: GoogleFonts.outfit(
                        color: isCurrent ? Colors.white : AppColors.textSecondary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _currentPage < totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _currentPage < totalPages
                      ? AppColors.surfaceVariant
                      : AppColors.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _currentPage < totalPages
                        ? AppColors.border
                        : AppColors.border.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _currentPage < totalPages ? Colors.white : Colors.white24,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

