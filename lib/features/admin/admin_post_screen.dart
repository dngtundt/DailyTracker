import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/post_model.dart';

class AdminPostScreen extends StatefulWidget {
  const AdminPostScreen({super.key});

  @override
  State<AdminPostScreen> createState() => _AdminPostScreenState();
}

class _AdminPostScreenState extends State<AdminPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _imgUrlCtrl = TextEditingController();
  bool _loading = false;
  XFile? _selectedXFile;
  final _picker = ImagePicker();

  final List<String> _targetCountries = [];
  final List<String> _targetRanks = [];
  final List<String> _targetGenders = [];
  final List<String> _targetBmiLevels = [];

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

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedXFile = picked);
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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _imgUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final admin = context.read<AuthService>().currentUser;
    if (admin == null) return;

    String? imageUrl = _imgUrlCtrl.text.trim().isEmpty ? null : _imgUrlCtrl.text.trim();
    
    if (_selectedXFile != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('posts')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        if (kIsWeb) {
          final bytes = await _selectedXFile!.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(_selectedXFile!.path));
        }
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        // Fallback to catbox.moe if Firebase Storage is not enabled or fails
        try {
          final request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
          request.fields['reqtype'] = 'fileupload';
          
          if (kIsWeb) {
            final bytes = await _selectedXFile!.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'fileToUpload',
              bytes,
              filename: _selectedXFile!.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath('fileToUpload', _selectedXFile!.path));
          }
          
          final response = await request.send();
          if (response.statusCode == 200) {
            final resBody = await response.stream.bytesToString();
            if (resBody.startsWith('http')) {
              imageUrl = resBody.trim();
            } else {
              throw Exception(resBody);
            }
          } else {
            throw Exception('HTTP status ${response.statusCode}');
          }
        } catch (fallbackError) {
          if (mounted) {
            setState(() => _loading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi tải ảnh: $fallbackError'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
    }

    final post = PostModel(
      adminId: admin.id!,
      adminName: admin.username,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      targetCountries: List<String>.from(_targetCountries),
      targetRanks: List<String>.from(_targetRanks),
      targetGenders: List<String>.from(_targetGenders),
      targetBmiLevels: List<String>.from(_targetBmiLevels),
    );
    
    await FirestoreService.instance.insertPost(post);
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Bài đăng đã được đăng thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Tạo bài đăng', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _publish,
            child: Text('Đăng', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Preview banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(Icons.broadcast_on_personal_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Bài đăng này sẽ hiển thị trong feed chính của nhóm đối tượng được chọn lọc.',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Tiêu đề *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Tiêu đề bài đăng...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              maxLines: 2,
              validator: (v) => (v == null || v.isEmpty) ? 'Nhập tiêu đề' : null,
            ),
            const Divider(color: Color(0xFF2A3650)),
            const SizedBox(height: 16),
            Text('Nội dung *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _contentCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
              maxLines: 12,
              decoration: const InputDecoration(
                hintText: 'Chia sẻ lời khuyên, động lực, hoặc tin tức cho cộng đồng...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Nhập nội dung' : null,
            ),
            const Divider(color: Color(0xFF2A3650)),
            const SizedBox(height: 16),
            Text('Hình ảnh đính kèm (Không bắt buộc)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (_selectedXFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_selectedXFile!.path, width: double.infinity, height: 200, fit: BoxFit.cover)
                        : Image.file(File(_selectedXFile!.path), width: double.infinity, height: 200, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () => setState(() => _selectedXFile = null),
                    ),
                  )
                ],
              )
            else
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                    label: const Text('Chọn ảnh từ máy', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            const SizedBox(height: 12),
            if (_selectedXFile == null) ...[
              const Center(child: Text('Hoặc', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imgUrlCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Dán đường link (URL) hình ảnh...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.link_rounded, color: AppColors.textSecondary),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            const Divider(color: Color(0xFF2A3650)),
            const SizedBox(height: 16),
            Text('Bộ lọc người nhận', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Người dùng phải khớp tất cả bộ lọc đang chọn. Nếu bỏ trống toàn bộ, bài đăng áp dụng cho tất cả.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
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

            const SizedBox(height: 24),
            const Divider(color: Color(0xFF2A3650)),
            const SizedBox(height: 16),
            // Emoji quick-insert
            Text('Gợi ý emoji', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['🎯', '💪', '🌟', '🔥', '💡', '🏆', '🚀', '❤️', '✅', '📢'].map((emoji) =>
                GestureDetector(
                  onTap: () {
                    final pos = _contentCtrl.selection.baseOffset;
                    final text = _contentCtrl.text;
                    final newText = pos < 0 ? text + emoji : text.substring(0, pos) + emoji + text.substring(pos);
                    _contentCtrl.text = newText;
                    _contentCtrl.selection = TextSelection.collapsed(offset: (pos < 0 ? text.length : pos) + emoji.length);
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 32),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _publish,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('Đăng bài viết'),
                ),
              ),
          ]),
        ),
      ),
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
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      if (_targetCountries.isNotEmpty) 'Quốc gia: ${_targetCountries.join(', ')}',
      if (_targetRanks.isNotEmpty) 'Hạng: ${_targetRanks.map(_rankLabel).join(', ')}',
      if (_targetGenders.isNotEmpty) 'Giới tính: ${_targetGenders.join(', ')}',
      if (_targetBmiLevels.isNotEmpty) 'BMI: ${_targetBmiLevels.map(_bmiLabel).join(', ')}',
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
            appliedFilters.isEmpty ? 'Tất cả người dùng' : appliedFilters.join('\n'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
