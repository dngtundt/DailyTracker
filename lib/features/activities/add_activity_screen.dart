import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/models/activity_model.dart';

class AddActivityScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddActivityScreen({super.key, required this.selectedDate});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'work';
  String _startTime = '08:00';
  String _endTime = '09:00';
  bool _hasReminder = false;
  bool _loading = false;
  
  List<ActivityModel> _suggestions = [];
  bool _loadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final acts = await FirestoreService.instance.getSuggestedActivities(user.id!);
      if (mounted) {
        setState(() {
          _suggestions = acts;
          _loadingSuggestions = false;
        });
      }
    }
  }

  void _applySuggestion(ActivityModel act) {
    setState(() {
      _titleCtrl.text = act.title;
      _descCtrl.text = act.description ?? '';
      _category = act.category;
      _startTime = act.startTime;
      _endTime = act.endTime ?? _endTime;
    });
  }

  final List<Map<String, dynamic>> _categories = [
    {'value': 'work', 'label': 'Công việc', 'icon': Icons.work_outline_rounded, 'color': AppColors.info},
    {'value': 'sport', 'label': 'Thể thao', 'icon': Icons.fitness_center_rounded, 'color': AppColors.accent},
    {'value': 'food', 'label': 'Ăn uống', 'icon': Icons.restaurant_rounded, 'color': AppColors.success},
    {'value': 'rest', 'label': 'Nghỉ ngơi', 'icon': Icons.hotel_rounded, 'color': AppColors.secondary},
    {'value': 'other', 'label': 'Khác', 'icon': Icons.star_outline_rounded, 'color': AppColors.primary},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }

      final activity = ActivityModel(
        userId: user.id!,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: widget.selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        category: _category,
        hasReminder: _hasReminder,
        reminderTime: _hasReminder ? _startTime : null,
        isDone: false,
        createdAt: DateTime.now(),
      );

      await FirestoreService.instance.insertActivity(activity);

      if (_hasReminder) {
        final parts = _startTime.split(':');
        final reminderDateTime = DateTime(
          widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day,
          int.parse(parts[0]), int.parse(parts[1]),
        );
        if (reminderDateTime.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleActivityReminder(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: '⏰ Nhắc nhở: ${_titleCtrl.text}',
            body: _descCtrl.text.isNotEmpty ? _descCtrl.text : 'Đây là thời gian cho hoạt động của bạn!',
            scheduledTime: reminderDateTime,
          );
        }
      }

      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã thêm hoạt động thành công!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e, st) {
      if (mounted) {
        setState(() => _loading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Lỗi'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final parts = (isStart ? _startTime : _endTime).split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() { if (isStart) _startTime = formatted; else _endTime = formatted; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Thêm hoạt động', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text('Lưu', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Date display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, dd/MM/yyyy').format(widget.selectedDate),
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            if (!_loadingSuggestions && _suggestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
                  const SizedBox(width: 6),
                  _buildLabel('Gợi ý từ lịch sử'),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _suggestions.map((act) {
                    final catColor = _categories.firstWhere((c) => c['value'] == act.category, orElse: () => _categories.first)['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(Icons.add_rounded, size: 16, color: catColor),
                        label: Text(act.title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: AppColors.surface,
                        side: BorderSide(color: catColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onPressed: () => _applySuggestion(act),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Title
            _buildLabel('Tiêu đề hoạt động *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Ví dụ: Họp nhóm, Tập gym,...'),
              validator: (v) => (v == null || v.isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const SizedBox(height: 16),
            // Description
            _buildLabel('Ghi chú'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Mô tả chi tiết hoạt động...'),
            ),
            const SizedBox(height: 16),
            // Category
            _buildLabel('Danh mục'),
            const SizedBox(height: 8),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            // Time
            _buildLabel('Thời gian'),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _buildTimePicker('Bắt đầu', _startTime, () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(child: _buildTimePicker('Kết thúc', _endTime, () => _pickTime(false))),
            ]),
            const SizedBox(height: 16),
            // Reminder toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('🔔 Bật nhắc nhở', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text('Thông báo vào thời điểm bắt đầu', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                value: _hasReminder,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _hasReminder = v),
              ),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Lưu hoạt động'),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500));
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((cat) {
        final isSelected = _category == cat['value'];
        final color = cat['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _category = cat['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(cat['icon'] as IconData, color: isSelected ? color : AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(cat['label'] as String, style: TextStyle(color: isSelected ? color : AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimePicker(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.access_time_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Text(time, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ]),
        ]),
      ),
    );
  }
}
