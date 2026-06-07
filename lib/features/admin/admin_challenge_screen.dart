import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/challenge_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

class AdminChallengeScreen extends StatefulWidget {
  final ChallengeModel? challenge;
  const AdminChallengeScreen({super.key, this.challenge});

  @override
  State<AdminChallengeScreen> createState() => _AdminChallengeScreenState();
}

class _AdminChallengeScreenState extends State<AdminChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '50');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _category = 'fitness';
  bool _loading = false;

  final List<String> _targetCountries = [];
  final List<String> _targetRanks = [];
  final List<String> _targetGenders = [];
  final List<String> _targetBmiLevels = [];

  @override
  void initState() {
    super.initState();
    if (widget.challenge != null) {
      _titleCtrl.text = widget.challenge!.title;
      _descCtrl.text = widget.challenge!.description;
      _pointsCtrl.text = widget.challenge!.points.toString();
      _category = widget.challenge!.category;
      try {
        _startDate = DateFormat('yyyy-MM-dd').parse(widget.challenge!.startDate);
      } catch (e) {
        _startDate = DateTime.now();
      }
      try {
        _endDate = DateFormat('yyyy-MM-dd').parse(widget.challenge!.endDate);
      } catch (e) {
        _endDate = DateTime.now();
      }
      _targetCountries.addAll(widget.challenge!.targetCountries);
      _targetRanks.addAll(widget.challenge!.targetRanks);
      _targetGenders.addAll(widget.challenge!.targetGenders);
      _targetBmiLevels.addAll(widget.challenge!.targetBmiLevels);
    }
  }

  static const List<String> _countries = [
    'Việt Nam',
    'Mỹ',
    'Nhật Bản',
    'Hàn Quốc',
    'Trung Quốc',
    'Đức',
    'Pháp',
    'Anh',
    'Úc',
    'Canada',
    'Singapore',
    'Thái Lan',
    'Malaysia',
    'Indonesia',
    'Philippines',
    'Khác',
  ];

  static const List<String> _ranks = [
    'iron',
    'bronze',
    'gold',
    'platinum',
    'diamond',
    'master',
  ];

  static const List<String> _genders = ['Nam', 'Nữ', 'Khác'];
  static const List<String> _bmiLevels = [
    'underweight',
    'normal',
    'overweight',
    'obese',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  void _toggleSelection(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _publishChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    final admin = context.read<AuthService>().currentUser;
    if (admin == null) return;

    setState(() => _loading = true);

    final isEditing = widget.challenge != null;
    try {
      final challenge = ChallengeModel(
        id: widget.challenge?.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        points: int.parse(_pointsCtrl.text.trim()),
        category: _category,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate),
        targetCountries: List<String>.from(_targetCountries),
        targetRanks: List<String>.from(_targetRanks),
        targetGenders: List<String>.from(_targetGenders),
        targetBmiLevels: List<String>.from(_targetBmiLevels),
        adminId: widget.challenge?.adminId ?? admin.id,
        adminName: widget.challenge?.adminName ?? admin.username,
        createdAt: widget.challenge?.createdAt ?? DateTime.now(),
      );

      if (isEditing) {
        await FirestoreService.instance.updateChallenge(challenge);
      } else {
        await FirestoreService.instance.insertChallenge(challenge);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '✅ Đã cập nhật thử thách thành công' : '✅ Đã tạo thử thách thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Không thể cập nhật thử thách: $e' : 'Không thể tạo thử thách: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.challenge != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          isEditing ? 'Chỉnh sửa thử thách' : 'Tạo thử thách',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publishChallenge,
            child: Text(
              isEditing ? 'Cập nhật' : 'Lưu',
              style: TextStyle(
                color: _loading ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _titleCtrl,
                label: 'Tiêu đề thử thách *',
                hint: 'Ví dụ: Đi bộ 8.000 bước',
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descCtrl,
                label: 'Mô tả *',
                hint: 'Nêu rõ mục tiêu người dùng cần hoàn thành',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCategorySelector(),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _buildPointsField(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 20),
              _sectionTitle('Bộ lọc người nhận'),
              const SizedBox(height: 8),
              Text(
                'Người dùng phải khớp tất cả bộ lọc đang chọn. Nếu bỏ trống toàn bộ, thử thách áp dụng cho tất cả.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildChipGroup(
                title: 'Quốc gia',
                values: _countries,
                selected: _targetCountries,
                onToggle: (value) => _toggleSelection(_targetCountries, value),
              ),
              const SizedBox(height: 16),
              _buildChipGroup(
                title: 'Xếp hạng',
                values: _ranks,
                selected: _targetRanks,
                onToggle: (value) => _toggleSelection(_targetRanks, value),
                labelBuilder: _rankLabel,
              ),
              const SizedBox(height: 16),
              _buildChipGroup(
                title: 'Giới tính',
                values: _genders,
                selected: _targetGenders,
                onToggle: (value) => _toggleSelection(_targetGenders, value),
              ),
              const SizedBox(height: 16),
              _buildChipGroup(
                title: 'Thể trạng BMI',
                values: _bmiLevels,
                selected: _targetBmiLevels,
                onToggle: (value) => _toggleSelection(_targetBmiLevels, value),
                labelBuilder: _bmiLabel,
              ),
              const SizedBox(height: 20),
              _buildAudiencePreview(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _publishChallenge,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.emoji_events_rounded,
                          color: Colors.white),
                  label: Text(_loading
                      ? 'Đang lưu...'
                      : (isEditing ? 'Cập nhật thử thách' : 'Tạo thử thách')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Thử thách sau khi tạo sẽ xuất hiện trong mục "Thử thách hôm nay" của đúng nhóm người dùng phù hợp.',
              style: const TextStyle(
                  color: AppColors.primary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Trường này là bắt buộc';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    const categories = [
      ('fitness', 'Thể thao'),
      ('nutrition', 'Dinh dưỡng'),
      ('mindset', 'Tinh thần'),
      ('productivity', 'Năng suất'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Danh mục',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _category,
          dropdownColor: AppColors.surfaceVariant,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(),
          items: categories
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.$1,
                  child: Text(item.$2),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _category = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPointsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Điểm *',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pointsCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: '50'),
          validator: (value) {
            final points = int.tryParse(value ?? '');
            if (points == null || points <= 0) {
              return 'Điểm > 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(isStart: true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Từ ngày',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_startDate),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _pickDate(isStart: false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đến ngày',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_endDate),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChipGroup({
    required String title,
    required List<String> values,
    required List<String> selected,
    required ValueChanged<String> onToggle,
    String Function(String)? labelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            return FilterChip(
              label: Text(labelBuilder?.call(value) ?? value),
              selected: isSelected,
              onSelected: (_) => onToggle(value),
              selectedColor: AppColors.primary.withOpacity(0.22),
              checkmarkColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAudiencePreview() {
    final appliedFilters = <String>[
      if (_targetCountries.isNotEmpty)
        'Quốc gia: ${_targetCountries.join(', ')}',
      if (_targetRanks.isNotEmpty)
        'Hạng: ${_targetRanks.map(_rankLabel).join(', ')}',
      if (_targetGenders.isNotEmpty) 'Giới tính: ${_targetGenders.join(', ')}',
      if (_targetBmiLevels.isNotEmpty)
        'BMI: ${_targetBmiLevels.map(_bmiLabel).join(', ')}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phạm vi áp dụng',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            appliedFilters.isEmpty
                ? 'Tất cả người dùng'
                : appliedFilters.join('\n'),
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }

  String _rankLabel(String rank) {
    const labels = {
      'iron': 'Sắt',
      'bronze': 'Đồng',
      'gold': 'Vàng',
      'platinum': 'Bạch Kim',
      'diamond': 'Kim Cương',
      'master': 'Cao Thủ',
    };
    return labels[rank] ?? rank;
  }

  String _bmiLabel(String bmiLevel) {
    const labels = {
      'underweight': 'Thiếu cân',
      'normal': 'Bình thường',
      'overweight': 'Thừa cân',
      'obese': 'Béo phì',
    };
    return labels[bmiLevel] ?? bmiLevel;
  }
}
