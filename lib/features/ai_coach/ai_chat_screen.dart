import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/providers/locale_provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  bool isLoading;

  _AiChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isLoading = false,
  });
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ctrl     = TextEditingController();
  final _scroll   = ScrollController();
  final List<_AiChatMessage> _messages = [];
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _addWelcome() {
    final loc = context.read<LocaleProvider>();
    _messages.add(_AiChatMessage(
      text: loc.tr(
        '👋 Xin chào! Tôi là AI Life Coach của bạn.\n\nBạn có thể hỏi tôi về:\n• 🍽️ Chế độ dinh dưỡng & ăn uống\n• 🏃 Kế hoạch tập luyện\n• 😴 Chất lượng giấc ngủ\n• 💡 Lời khuyên năng suất\n• 📅 Lập kế hoạch ngày của bạn\n\nHãy đặt câu hỏi cho tôi!',
        '👋 Hello! I\'m your AI Life Coach.\n\nYou can ask me about:\n• 🍽️ Nutrition & diet\n• 🏃 Workout plans\n• 😴 Sleep quality\n• 💡 Productivity tips\n• 📅 Daily planning\n\nFeel free to ask me anything!',
      ),
      isUser: false,
      time: DateTime.now(),
    ));
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _typing) return;
    _ctrl.clear();

    setState(() {
      _messages.add(_AiChatMessage(text: text, isUser: true, time: DateTime.now()));
      _typing = true;
    });
    _scrollToBottom();

    // Add loading bubble
    final loadingMsg = _AiChatMessage(
      text: '...', isUser: false, time: DateTime.now(), isLoading: true,
    );
    setState(() => _messages.add(loadingMsg));
    _scrollToBottom();

    // Build AI context
    final user  = context.read<AuthService>().currentUser;
    final recent = user != null
        ? await FirestoreService.instance.getRecentActivities(user.id!, days: 7)
        : <dynamic>[];
    final loc = context.read<LocaleProvider>();
    final isVi = loc.isVietnamese;

    final response = await AiService.instance.chat(
      userMessage: text,
      user: user,
      recentActivities: recent.cast(),
      isVietnamese: isVi,
    );

    if (!mounted) return;
    setState(() {
      _messages.remove(loadingMsg);
      _messages.add(_AiChatMessage(text: response, isUser: false, time: DateTime.now()));
      _typing = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg  = isDark ? AppColors.background   : const Color(0xFFF0F4FF);
    final surf = isDark ? AppColors.surface      : Colors.white;
    final border = isDark ? AppColors.border     : const Color(0xFFD1D9F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surf,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loc.tr('AI Life Coach', 'AI Life Coach'),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1A1040))),
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(loc.tr('Đang hoạt động', 'Online'),
                  style: const TextStyle(color: AppColors.success, fontSize: 10)),
            ]),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _buildBubble(_messages[i], isDark),
          ),
        ),
        _buildInputBar(loc, surf, border, isDark),
      ]),
    );
  }

  Widget _buildBubble(_AiChatMessage msg, bool isDark) {
    final isUser = msg.isUser;
    final textColor = isDark ? Colors.white : (isUser ? Colors.white : const Color(0xFF1A1040));
    final bgColor = isUser
        ? AppColors.primary
        : (isDark ? AppColors.surface : const Color(0xFFEEF2FF));
    final borderColor = isDark ? AppColors.border : const Color(0xFFD1D9F0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: borderColor),
              ),
              child: msg.isLoading
                  ? _buildTypingDots()
                  : Text(msg.text, style: TextStyle(color: textColor, fontSize: 14, height: 1.5)),
            ),
          ).animate().fadeIn().slideX(begin: isUser ? 0.1 : -0.1),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) =>
      Container(
        width: 6, height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
      ).animate(delay: Duration(milliseconds: i * 200), onPlay: (c) => c.repeat())
       .fadeIn(duration: 400.ms).then().fadeOut(duration: 400.ms),
    ));
  }

  Widget _buildInputBar(LocaleProvider loc, Color surf, Color border, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: surf,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            maxLines: null,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1A1040)),
            decoration: InputDecoration(
              hintText: loc.tr('Hỏi AI về sức khỏe, dinh dưỡng...', 'Ask AI about health, nutrition...'),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: isDark ? AppColors.surfaceVariant : const Color(0xFFF0F4FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: _typing ? null : AppColors.primaryGradient,
              color: _typing ? AppColors.border : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              _typing ? Icons.hourglass_empty_rounded : Icons.send_rounded,
              color: Colors.white, size: 20,
            ),
          ),
        ),
      ]),
    );
  }
}
