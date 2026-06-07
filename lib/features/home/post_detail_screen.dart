import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/post_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitComment(PostModel post) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    setState(() => _submitting = true);
    final comment = CommentModel(
      userId: user.id!,
      username: user.username,
      content: text,
      createdAt: DateTime.now(),
    );

    try {
      await FirestoreService.instance.addCommentToPost(widget.postId, comment);
      _commentCtrl.clear();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi bình luận: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    try {
      await FirestoreService.instance.toggleLikePost(widget.postId, user.id!);
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<PostModel>(
      stream: FirestoreService.instance.getPostStream(widget.postId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
            body: Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white))),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final post = snapshot.data;
        if (post == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
            body: const Center(child: Text('Bài viết không tồn tại', style: TextStyle(color: Colors.white))),
          );
        }

        final likedByMe = post.likes.contains(user.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0.5,
            title: Text('Bài viết', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Content Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Header
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            post.adminName,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Quản trị viên • ${_formatTimeAgo(post.createdAt)}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Post Title
                            Text(
                              post.title,
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.3),
                            ),
                            const SizedBox(height: 10),
                            // Post Content Body
                            Text(
                              post.content,
                              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      // Post Image (Full Width)
                      if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: InteractiveViewer(
                            child: Image.network(
                              post.imageUrl!,
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                color: AppColors.surface,
                                child: const Center(
                                  child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary, size: 32),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Likes & Comments Count Stats Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.thumb_up_rounded, color: Colors.white, size: 10),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likes.length} lượt thích',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              '${post.comments.length} bình luận',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.border, height: 1),

                      // Action buttons: Like and Comment
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _toggleLike,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      likedByMe ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                      color: likedByMe ? Colors.blue : AppColors.textSecondary,
                                      size: 20,
                                    ).animate(target: likedByMe ? 1.0 : 0.0).scale(begin: const Offset(0.8, 0.8), curve: Curves.bounceOut),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thích',
                                      style: TextStyle(
                                        color: likedByMe ? Colors.blue : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                // Focus textfield
                              },
                              child: const Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.comment_outlined, color: AppColors.textSecondary, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bình luận',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 1),

                      // Comments List Section
                      if (post.comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary.withOpacity(0.4), size: 40),
                                const SizedBox(height: 12),
                                const Text('Chưa có bình luận nào.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                const Text('Hãy là người đầu tiên chia sẻ cảm nghĩ!', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: post.comments.length,
                          itemBuilder: (context, idx) {
                            final comment = post.comments[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User avatar placeholder
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Comment bubble container
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.only(
                                              topRight: const Radius.circular(14),
                                              bottomLeft: const Radius.circular(14),
                                              bottomRight: const Radius.circular(14),
                                              topLeft: Radius.circular(comment.userId == user.id ? 14 : 4),
                                            ),
                                            border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.username,
                                                style: TextStyle(
                                                  color: comment.userId == post.adminId ? Colors.blue : Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.content,
                                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 4.0),
                                          child: Text(
                                            _formatTimeAgo(comment.createdAt),
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1, duration: 200.ms);
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Input Row
              Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextFormField(
                          controller: _commentCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          decoration: const InputDecoration(
                            hintText: 'Viết bình luận...',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                            onPressed: () => _submitComment(post),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
