import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageCtrl = PageController();
  int _currentPage = 0;

  // Page 1 fields
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _pass2Ctrl    = TextEditingController();
  bool _obscurePass   = true;
  bool _obscurePass2  = true;

  // Page 2 fields
  String _gender      = 'Nam';
  final _ageCtrl      = TextEditingController();
  final _heightCtrl   = TextEditingController();
  final _weightCtrl   = TextEditingController();
  String _country     = 'Việt Nam';
  final _occupCtrl    = TextEditingController();

  bool _loading = false;
  String? _error;

  static const List<String> _countries = [
    'Việt Nam', 'Mỹ', 'Nhật Bản', 'Hàn Quốc', 'Trung Quốc',
    'Đức', 'Pháp', 'Anh', 'Úc', 'Canada', 'Singapore',
    'Thái Lan', 'Malaysia', 'Indonesia', 'Philippines', 'Khác',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _pass2Ctrl.dispose(); _ageCtrl.dispose(); _heightCtrl.dispose();
    _weightCtrl.dispose(); _occupCtrl.dispose(); _pageCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate page 1 fields manually
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _passCtrl.text.length < 6 ||
        _passCtrl.text != _pass2Ctrl.text) {
      setState(() {
        if (_nameCtrl.text.trim().isEmpty) _error = 'Vui lòng nhập họ tên';
        else if (_emailCtrl.text.trim().isEmpty) _error = 'Vui lòng nhập email';
        else if (_passCtrl.text.length < 6) _error = 'Mật khẩu ít nhất 6 ký tự';
        else _error = 'Mật khẩu xác nhận không khớp';
      });
      return;
    }
    setState(() => _error = null);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    setState(() => _currentPage = 1);
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    final auth = context.read<AuthService>();
    final err = await auth.register(
      username: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      gender: _gender,
      age: int.tryParse(_ageCtrl.text),
      heightCm: double.tryParse(_heightCtrl.text),
      weightKg: double.tryParse(_weightCtrl.text),
      country: _country,
      occupation: _occupCtrl.text.trim().isNotEmpty ? _occupCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E1A), Color(0xFF1A1040)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildTopBar(),
            _buildProgress(),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (_currentPage == 1) {
              _pageCtrl.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
              setState(() { _currentPage = 0; _error = null; });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        Expanded(child: Center(
          child: Text(
            _currentPage == 0 ? 'Tạo tài khoản' : 'Thông tin cá nhân',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        )),
        const SizedBox(width: 40),
      ]),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Row(children: [
        Expanded(child: _progressDot(0, 'Tài khoản')),
        Container(height: 2, width: 40, color: _currentPage >= 1 ? AppColors.primary : AppColors.border),
        Expanded(child: _progressDot(1, 'Hồ sơ')),
      ]),
    );
  }

  Widget _progressDot(int step, String label) {
    final active = _currentPage >= step;
    return Column(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 28, height: 28,
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : AppColors.border,
          shape: BoxShape.circle,
        ),
        child: Center(child: active
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
            : Text('${step + 1}', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        color: active ? AppColors.primary : AppColors.textSecondary,
        fontSize: 11, fontWeight: FontWeight.w500,
      )),
    ]);
  }

  // ── PAGE 1: Account info ─────────────────────────────────────────────────

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        _buildLogo(),
        const SizedBox(height: 24),
        _buildCard(children: [
          _field(_nameCtrl,  'Họ và tên *', Icons.person_outline, TextInputType.name),
          _gap,
          _field(_emailCtrl, 'Email *', Icons.email_outlined, TextInputType.emailAddress),
          _gap,
          _passwordField(_passCtrl, 'Mật khẩu *', _obscurePass,
              () => setState(() => _obscurePass = !_obscurePass)),
          _gap,
          _passwordField(_pass2Ctrl, 'Xác nhận mật khẩu *', _obscurePass2,
              () => setState(() => _obscurePass2 = !_obscurePass2)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _errorBox(_error!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Tiếp theo'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Đã có tài khoản? ', style: TextStyle(color: AppColors.textSecondary)),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text('Đăng nhập', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ]),
    ).animate().fadeIn();
  }

  // ── PAGE 2: Personal info ─────────────────────────────────────────────────

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Thông tin này giúp AI cá nhân hóa lời khuyên sức khỏe cho bạn.',
              style: TextStyle(color: AppColors.primary, fontSize: 12, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        _buildCard(children: [
          // Gender
          Text('Giới tính *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: ['Nam', 'Nữ', 'Khác'].map((g) {
            final sel = _gender == g;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppColors.primaryGradient : null,
                  color: sel ? null : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? Colors.transparent : AppColors.border),
                ),
                child: Center(child: Text(g, style: TextStyle(
                  color: sel ? Colors.white : AppColors.textSecondary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ))),
              ),
            ));
          }).toList()),
          _gap,

          // Age + Height + Weight in a row
          Row(children: [
            Expanded(child: _field(_ageCtrl, 'Tuổi', Icons.cake_outlined, TextInputType.number, hint: 'VD: 22')),
            const SizedBox(width: 10),
            Expanded(child: _field(_heightCtrl, 'Cao (cm)', Icons.height_rounded, TextInputType.number, hint: 'VD: 170')),
            const SizedBox(width: 10),
            Expanded(child: _field(_weightCtrl, 'Nặng (kg)', Icons.monitor_weight_outlined, TextInputType.number, hint: 'VD: 65')),
          ]),
          _gap,

          // BMI preview
          if (_heightCtrl.text.isNotEmpty && _weightCtrl.text.isNotEmpty)
            _buildBmiPreview(),

          // Country dropdown
          Text('Quốc gia', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _country,
            dropdownColor: AppColors.surfaceVariant,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.flag_outlined, color: AppColors.primary, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _country = v!),
          ),
          _gap,

          _field(_occupCtrl, 'Nghề nghiệp', Icons.work_outline_rounded, TextInputType.text,
              hint: 'VD: Sinh viên, Kỹ sư,...'),

          if (_error != null) ...[const SizedBox(height: 10), _errorBox(_error!)],
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Tạo tài khoản'),
                    ]),
            ),
          ),
          const SizedBox(height: 10),
          Center(child: TextButton(
            onPressed: _loading ? null : _register,
            child: Text('Bỏ qua, điền sau', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          )),
        ]),
      ]),
    ).animate().fadeIn();
  }

  Widget _buildBmiPreview() {
    final h = double.tryParse(_heightCtrl.text);
    final w = double.tryParse(_weightCtrl.text);
    if (h == null || w == null || h <= 0) return const SizedBox();
    final bmi = w / ((h / 100) * (h / 100));
    String label; Color color;
    if (bmi < 18.5) { label = 'Thiếu cân'; color = AppColors.info; }
    else if (bmi < 25) { label = 'Bình thường ✅'; color = AppColors.success; }
    else if (bmi < 30) { label = 'Thừa cân'; color = AppColors.warning; }
    else { label = 'Béo phì'; color = AppColors.error; }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Text('⚖️ BMI: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(bmi.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
        Text('  –  $label', style: TextStyle(color: color, fontSize: 13)),
      ]),
    );
  }

  Widget _buildLogo() {
    return Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.track_changes_rounded, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 14),
      Text('DailyTracker', style: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white,
      )),
    ]).animate().fadeIn();
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      TextInputType type, {String? hint}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}), // rebuild for BMI preview
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }

  Widget _passwordField(TextEditingController ctrl, String label,
      bool obscure, VoidCallback toggle) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textSecondary, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }

  static const Widget _gap = SizedBox(height: 16);
}
