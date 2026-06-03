import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/activity_model.dart';
import '../activities/add_activity_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  DateTime _selectedDate = DateTime.now();
  List<ActivityModel> _activities = [];
  bool _loading = true;
  bool _hasDailyTemplate = false;
  String _dailyTemplateName = 'Mẫu mặc định';

  @override
  void initState() {
    super.initState();
    _loadActivities();
    _loadTemplateInfo();
  }

  Future<void> _loadActivities() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final acts = await FirestoreService.instance
        .getActivitiesForDate(user.id!, _selectedDate);
    if (mounted)
      setState(() {
        _activities = acts;
        _loading = false;
      });
  }

  Future<void> _loadTemplateInfo() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    final template = await FirestoreService.instance.getDailyTemplate(user.id!);
    if (!mounted) return;

    setState(() {
      _hasDailyTemplate = template != null && template.items.isNotEmpty;
      if (template != null && template.name.isNotEmpty) {
        _dailyTemplateName = template.name;
      }
    });
  }

  Future<void> _toggleDone(ActivityModel act) async {
    setState(() {
      final index = _activities.indexWhere((a) => a.id == act.id);
      if (index != -1) {
        _activities[index] = _activities[index].copyWith(isDone: !act.isDone);
      }
    });
    FirestoreService.instance.updateActivityDone(act.id!, !act.isDone);
  }

  Future<void> _deleteActivity(ActivityModel act) async {
    setState(() {
      _activities.removeWhere((a) => a.id == act.id);
    });
    NotificationService.instance.cancelNotification(act.id.hashCode);
    FirestoreService.instance.deleteActivity(act.id!);
  }

  Future<void> _copyYesterday() async {
    setState(() => _loading = true);
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final copiedActs = await FirestoreService.instance
        .copyYesterdayActivities(user.id!, _selectedDate);

    for (final act in copiedActs) {
      if (act.hasReminder) {
        final parts = act.startTime.split(':');
        final reminderDateTime = DateTime(
          act.date.year,
          act.date.month,
          act.date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        if (reminderDateTime.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleActivityReminder(
            id: act.id.hashCode,
            title: '⏰ Nhắc nhở: ${act.title}',
            body: act.description != null && act.description!.isNotEmpty
                ? act.description!
                : 'Đây là thời gian cho hoạt động của bạn!',
            scheduledTime: reminderDateTime,
          );
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã sao chép ${copiedActs.length} hoạt động!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    _loadActivities();
  }

  Future<void> _saveAsDailyTemplate() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    if (_activities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ngày này chưa có hoạt động để lưu làm mẫu'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    var draftTemplateName = _dailyTemplateName;
    final templateName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Lưu mẫu mặc định',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextFormField(
          initialValue: _dailyTemplateName,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Tên mẫu',
            hintText: 'Ví dụ: Lịch làm việc chuẩn',
          ),
          onChanged: (value) => draftTemplateName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              draftTemplateName.trim().isEmpty
                  ? 'Mẫu mặc định'
                  : draftTemplateName.trim(),
            ),
            child: const Text('Lưu mẫu'),
          ),
        ],
      ),
    );
    if (templateName == null) return;

    await FirestoreService.instance.saveDailyTemplate(
      userId: user.id!,
      name: templateName,
      activities: _activities,
    );
    await _loadTemplateInfo();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã lưu "$templateName" làm mẫu mặc định'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _applyDailyTemplate() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    if (!_hasDailyTemplate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bạn chưa có mẫu mặc định nào'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    var replaceExisting = false;
    if (_activities.isNotEmpty) {
      final action = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Áp dụng mẫu mặc định',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Ngày ${DateFormat('dd/MM/yyyy').format(_selectedDate)} đang có ${_activities.length} hoạt động. Bạn muốn ghi đè hay thêm tiếp từ "$_dailyTemplateName"?',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'append'),
              child: const Text('Thêm vào'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, 'replace'),
              child: const Text('Ghi đè'),
            ),
          ],
        ),
      );

      if (action == null) return;
      replaceExisting = action == 'replace';
    }

    setState(() => _loading = true);
    final created = await FirestoreService.instance.applyDailyTemplate(
      userId: user.id!,
      targetDate: _selectedDate,
      replaceExisting: replaceExisting,
    );

    for (final activity in created) {
      await _scheduleReminderForActivity(activity);
    }

    await _loadActivities();
    await _loadTemplateInfo();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ Đã áp dụng "$_dailyTemplateName" với ${created.length} hoạt động'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _scheduleReminderForActivity(ActivityModel act) async {
    if (!act.hasReminder) return;

    final parts = act.startTime.split(':');
    final reminderDateTime = DateTime(
      act.date.year,
      act.date.month,
      act.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (reminderDateTime.isAfter(DateTime.now())) {
      await NotificationService.instance.scheduleActivityReminder(
        id: act.id.hashCode,
        title: '⏰ Nhắc nhở: ${act.title}',
        body: act.description != null && act.description!.isNotEmpty
            ? act.description!
            : 'Đây là thời gian cho hoạt động của bạn!',
        scheduledTime: reminderDateTime,
      );
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'work':
        return AppColors.info;
      case 'sport':
        return AppColors.accent;
      case 'food':
        return AppColors.success;
      case 'rest':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'sport':
        return Icons.fitness_center_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'rest':
        return Icons.hotel_rounded;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Lịch trình',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        actions: [
          IconButton(
            icon: Icon(
              Icons.content_paste_rounded,
              color: _hasDailyTemplate ? Colors.white : AppColors.textMuted,
            ),
            tooltip: 'Áp dụng mẫu mặc định',
            onPressed: _applyDailyTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
            tooltip: 'Lưu ngày này làm mẫu',
            onPressed: _saveAsDailyTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddActivityScreen(selectedDate: _selectedDate)),
        ).then((_) => _loadActivities()),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Thêm hoạt động',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _activities.isEmpty
                    ? _buildEmptyState()
                    : _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _loadActivities();
              },
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('EEEE, d/M/yyyy').format(_selectedDate),
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
                _loadActivities();
              },
              icon:
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ),
          ],
        ),
        // Day summary
        if (!_loading)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniStat(
                  'Tổng', '${_activities.length}', AppColors.primary),
              const SizedBox(width: 16),
              _buildMiniStat(
                  'Hoàn thành',
                  '${_activities.where((a) => a.isDone).length}',
                  AppColors.success),
              const SizedBox(width: 16),
              _buildMiniStat(
                  'Chờ xử lý',
                  '${_activities.where((a) => !a.isDone).length}',
                  AppColors.warning),
            ],
          ),
      ]),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 16)),
      Text(label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    ]);
  }

  Widget _buildTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final act = _activities[index];
        final color = _getCategoryColor(act.category);
        return _buildTimelineTile(act, color, index);
      },
    );
  }

  Widget _buildTimelineTile(ActivityModel act, Color color, int index) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(act.startTime,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
                if (act.endTime != null)
                  Text(act.endTime!,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Line connector
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)
                    ]),
              ),
              Expanded(
                child: Container(width: 2, color: AppColors.border),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Activity card
          Expanded(
            child: Dismissible(
              key: Key(act.id.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.white),
              ),
              onDismissed: (_) => _deleteActivity(act),
              child: GestureDetector(
                onTap: () => _toggleDone(act),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: act.isDone
                        ? AppColors.surface.withOpacity(0.5)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: act.isDone
                            ? AppColors.success.withOpacity(0.3)
                            : color.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(_getCategoryIcon(act.category),
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(act.title,
                              style: TextStyle(
                                color: act.isDone
                                    ? AppColors.textSecondary
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                decoration: act.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              )),
                          if (act.description != null &&
                              act.description!.isNotEmpty)
                            Text(act.description!,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                        ])),
                    if (act.hasReminder)
                      Icon(Icons.notifications_active_rounded,
                          color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Icon(
                      act.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color:
                          act.isDone ? AppColors.success : AppColors.textMuted,
                      size: 22,
                    ),
                  ]),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn()
                  .slideX(begin: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.event_note_rounded,
                color: AppColors.textSecondary, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Chưa có hoạt động nào',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 8),
          Text('Nhấn + để thêm hoạt động vào ngày này',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _copyYesterday,
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Sao chép từ hôm qua'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_hasDailyTemplate) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _applyDailyTemplate,
              icon: const Icon(Icons.content_paste_rounded, size: 18),
              label: Text('Dùng $_dailyTemplateName'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadActivities();
    }
  }
}
