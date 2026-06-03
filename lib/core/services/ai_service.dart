import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/activity_model.dart';

class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  static const String _apiKey = 'AIzaSyARAJ86vdu9OPs1q3ImcX2_6LDbkWq7T8U';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent';

  final Map<String, String> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTime.containsKey(key)) return false;
    final age = DateTime.now().difference(_cacheTime[key]!);
    return age.inHours < 12; // Cache valid for 12 hours
  }

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  bool get hasApiKey => _apiKey.isNotEmpty && _apiKey != 'YOUR_GEMINI_API_KEY_HERE';

  /// Analyzes user profile + recent activities and returns a personalized daily plan
  Future<String> getPersonalizedPlan({
    required UserModel user,
    required List<ActivityModel> recentActivities,
    String? targetDate,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'plan_${user.id}_$targetDate';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final prompt = _buildPersonalizedPrompt(user, recentActivities, targetDate);

    if (!hasApiKey) return _mockPersonalizedAdvice(user);

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 4096,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          _cache[cacheKey] = text;
          _cacheTime[cacheKey] = DateTime.now();
        }
        return text ?? _mockPersonalizedAdvice(user);
      } else if (resp.statusCode == 429) {
        return '⏳ AI đang quá tải (vượt giới hạn miễn phí). Vui lòng đợi khoảng 1 phút rồi tải lại nhé!\n\n${_mockPersonalizedAdvice(user)}';
      } else {
        return _mockPersonalizedAdvice(user);
      }
    } catch (_) {
      return _mockPersonalizedAdvice(user);
    }
  }

  /// Chat: single-turn conversation with full user context
  Future<String> chat({
    required String userMessage,
    required UserModel? user,
    required List<ActivityModel> recentActivities,
    bool isVietnamese = true,
  }) async {
    final lang = isVietnamese ? 'tiếng Việt' : 'English';
    final bmi  = user?.bmi?.toStringAsFixed(1) ?? 'N/A';

    final categories = recentActivities.map((a) => a.category).toList();
    final sportPct  = recentActivities.isEmpty ? 0 : categories.where((c) => c == 'sport').length * 100 ~/ recentActivities.length;
    final sportFreq = sportPct > 30 ? (isVietnamese ? 'tập luyện thường xuyên' : 'exercises regularly')
                    : sportPct > 10 ? (isVietnamese ? 'tập luyện trung bình' : 'exercises moderately')
                    : (isVietnamese ? 'ít tập luyện' : 'rarely exercises');

    final actsByDate = <String, List<ActivityModel>>{};
    for (final a in recentActivities) {
      final key = a.date.toIso8601String().substring(0, 10);
      actsByDate.putIfAbsent(key, () => []).add(a);
    }
    final actSummary = actsByDate.entries.take(7).map((e) {
      final dayActs = e.value.map((a) {
        final done = a.isDone ? '✅' : '⬜';
        return '$done ${a.startTime} ${a.title} (${a.category})';
      }).join('\n  ');
      return '📅 ${e.key}:\n  $dayActs';
    }).join('\n\n');

    final systemCtx = user == null ? '' : '''
[USER PROFILE]
Name: ${user.username} | Gender: ${user.gender ?? 'N/A'} | Age: ${user.age ?? 'N/A'}
BMI: $bmi (${user.bmiLabel.isNotEmpty ? user.bmiLabel : 'N/A'}) | Occupation: ${user.occupation ?? 'N/A'}
Rank: ${user.rank} (${user.points} pts) | Activity level: $sportFreq

[USER HABITS - RECENT ACTIVITIES]
$actSummary
''';

    final prompt = '''
You are an expert AI Life Coach. Respond ONLY in $lang.
Be warm, practical, and give specific actionable advice. Analyze the user's daily habits dataset provided above to answer the user's question in a highly personalized way. Prioritize addressing the user's specific schedule and activities.
CRITICAL: Keep your answer VERY concise (maximum 3-5 sentences). Do not write long paragraphs.
$systemCtx
User question: $userMessage
''';

    if (!hasApiKey) {
      return isVietnamese
          ? 'Cảm ơn câu hỏi của bạn! Dựa trên hồ sơ của bạn, tôi khuyên bạn nên duy trì thói quen vận động đều đặn, ăn đủ chất và ngủ đủ giấc. Hãy đặt câu hỏi cụ thể hơn để tôi tư vấn chi tiết nhé!'
          : 'Thanks for your question! Based on your profile, I recommend maintaining regular exercise, balanced nutrition, and adequate sleep. Ask me something more specific for detailed advice!';
    }

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 4096},
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?
            ?? (isVietnamese ? 'Xin lỗi, không thể kết nối AI lúc này.' : 'Sorry, AI is unavailable right now.');
      } else if (resp.statusCode == 429) {
        return isVietnamese ? '⏳ Bạn đã hỏi quá nhanh (vượt giới hạn miễn phí của AI). Vui lòng đợi khoảng 1 phút rồi thử lại nhé!' : '⏳ Rate limit exceeded. Please wait 1 minute.';
      }
      return 'Lỗi Server: ${resp.statusCode} - ${resp.body}';
    } catch (e) {
      return 'Lỗi kết nối mạng: $e';
    }
  }

  /// AI-powered explore recommendations based on user habits
  Future<String> getExploreRecommendations({
    required UserModel user,
    required List<ActivityModel> recentActivities,
    required String category, // 'workout' | 'nutrition' | 'mindset' | 'schedule'
    bool isVietnamese = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'explore_${user.id}_$category';
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final lang  = isVietnamese ? 'tiếng Việt' : 'English';
    final bmi   = user.bmi?.toStringAsFixed(1) ?? 'N/A';
    final cats  = recentActivities.map((a) => a.category).toList();
    final sportN = cats.where((c) => c == 'sport').length;
    final foodN  = cats.where((c) => c == 'food').length;

    final topicMap = {
      'workout': isVietnamese
          ? 'Gợi ý bài tập & vận động phù hợp với thể trạng'
          : 'Workout & exercise recommendations based on fitness level',
      'nutrition': isVietnamese
          ? 'Kế hoạch dinh dưỡng và thực đơn cụ thể'
          : 'Specific nutrition plan and meal suggestions',
      'mindset': isVietnamese
          ? 'Mẹo năng suất, thiền định và sức khỏe tinh thần'
          : 'Productivity tips, meditation, and mental wellness',
      'schedule': isVietnamese
          ? 'Tối ưu hóa lịch trình hằng ngày theo thói quen'
          : 'Daily schedule optimization based on habits',
    };
    final topic = topicMap[category] ?? topicMap['workout']!;

    final prompt = '''
You are an expert AI Life Coach. Respond ONLY in $lang.

USER PROFILE:
- Name: ${user.username} | Gender: ${user.gender ?? 'N/A'} | Age: ${user.age ?? 'N/A'}
- BMI: $bmi (${user.bmiLabel.isNotEmpty ? user.bmiLabel : 'N/A'})
- Occupation: ${user.occupation ?? 'N/A'} | Country: ${user.country ?? 'Vietnam'}
- Rank: ${user.rank} (${user.points} points)
- Exercise sessions last 7 days: $sportN | Food logs: $foodN
- Total activities: ${recentActivities.length}

TASK: $topic

Provide 4-5 specific, personalized recommendations with:
- Concrete activity name or action
- Duration/quantity
- Why it's suitable for this user's profile
Format each as a numbered item. Be concise and motivating.
''';

    if (!hasApiKey) return _mockExploreRec(user, category, isVietnamese);

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.75, 'maxOutputTokens': 4096},
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          _cache[cacheKey] = text;
          _cacheTime[cacheKey] = DateTime.now();
        }
        return text ?? _mockExploreRec(user, category, isVietnamese);
      } else if (resp.statusCode == 429) {
        return '⏳ Hệ thống AI đang bị quá tải yêu cầu. Bạn vui lòng đợi 1 phút rồi thử lại nhé!\n\n(Dưới đây là gợi ý tạm thời)\n${_mockExploreRec(user, category, isVietnamese)}';
      }
      return _mockExploreRec(user, category, isVietnamese);
    } catch (_) {
      return _mockExploreRec(user, category, isVietnamese);
    }
  }

  String _mockExploreRec(UserModel user, String cat, bool vi) {
    if (!vi) {
      return '1. Based on your profile, try 30-min cardio 3x/week\n2. Drink ${user.gender == 'Nam' ? '2.5L' : '2L'} water daily\n3. Sleep 7-8 hours before 11pm\n4. Use Pomodoro technique for work sessions\n5. Add 1 serving of vegetables to each meal';
    }
    final bmi = user.bmi;
    final workoutRec = bmi != null && bmi > 25
        ? 'Cardio 45 phút (chạy bộ/đạp xe) 4 ngày/tuần để giảm cân hiệu quả'
        : 'Kết hợp cardio 30 phút + tập kháng lực 3 ngày/tuần';
    return '''
1. 🏃 $workoutRec
2. 💧 Uống ${user.gender == 'Nữ' ? '1.8–2L' : '2–2.5L'} nước mỗi ngày, bắt đầu từ ly nước ấm buổi sáng
3. 🥗 Ưu tiên bữa ăn có đủ protein + rau xanh, hạn chế đồ chiên rán
4. 😴 Ngủ 7–8 tiếng, tắt thiết bị điện tử 30 phút trước khi ngủ
5. 🧘 Thiền 10 phút mỗi sáng để giảm stress và tăng tập trung
''';
  }

  /// Legacy: simple schedule advice (kept for backward compat)
  Future<String> getScheduleAdvice({
    required String username,
    required List<Map<String, dynamic>> activities,
    required String date,
  }) async {
    if (!hasApiKey) return _mockSimpleAdvice(username);

    final prompt = '''
Bạn là AI Life Coach. Hãy phân tích lịch trình sau của người dùng "$username" ngày $date và đưa ra lời khuyên ngắn gọn, thiết thực bằng tiếng Việt (tối đa 200 từ):

${activities.map((a) => '- ${a['time']} | ${a['title']} (${a['category']})').join('\n')}

Tập trung vào: thời gian biểu cân bằng, dinh dưỡng, vận động, và sức khỏe tinh thần.
''';

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 4096},
        }),
      ).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?
            ?? _mockSimpleAdvice(username);
      }
      return _mockSimpleAdvice(username);
    } catch (_) {
      return _mockSimpleAdvice(username);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  String _buildPersonalizedPrompt(
      UserModel user, List<ActivityModel> recentActivities, String? targetDate) {
    final bmi = user.bmi?.toStringAsFixed(1) ?? 'N/A';
    final bmiLabel = user.bmiLabel.isNotEmpty ? user.bmiLabel : '';

    // Summarize recent activities by day
    final actsByDate = <String, List<ActivityModel>>{};
    for (final a in recentActivities) {
      final key = a.date.toIso8601String().substring(0, 10);
      actsByDate.putIfAbsent(key, () => []).add(a);
    }

    final actSummary = actsByDate.entries.take(5).map((e) {
      final dayActs = e.value.map((a) {
        final done = a.isDone ? '✅' : '⬜';
        return '$done ${a.startTime} ${a.title} (${a.category})';
      }).join('\n  ');
      return '📅 ${e.key}:\n  $dayActs';
    }).join('\n\n');

    final categories = recentActivities.map((a) => a.category).toList();
    final sportCount = categories.where((c) => c == 'sport').length;
    final foodCount  = categories.where((c) => c == 'food').length;
    final workCount  = categories.where((c) => c == 'work').length;
    final restCount  = categories.where((c) => c == 'rest').length;

    return '''
Bạn là AI Life Coach thông minh. Dựa trên hồ sơ và lịch sử hoạt động của người dùng dưới đây, hãy tạo kế hoạch ngày ${targetDate ?? 'hôm nay'} CỤ THỂ và PHÙ HỢP với họ.

═══ HỒ SƠ NGƯỜI DÙNG ═══
• Tên: ${user.username}
• Giới tính: ${user.gender ?? 'N/A'}
• Tuổi: ${user.age?.toString() ?? 'N/A'}
• Chiều cao: ${user.heightCm?.toStringAsFixed(0) ?? 'N/A'} cm
• Cân nặng: ${user.weightKg?.toStringAsFixed(1) ?? 'N/A'} kg
• BMI: $bmi ${bmiLabel.isNotEmpty ? '($bmiLabel)' : ''}
• Quốc gia: ${user.country ?? 'Việt Nam'}
• Nghề nghiệp: ${user.occupation ?? 'N/A'}
• Hạng: ${user.rank} (${user.points} điểm)

═══ THỐNG KÊ 7 NGÀY GẦN ĐÂY ═══
• Tổng hoạt động: ${recentActivities.length}
• Thể thao: $sportCount lần
• Ăn uống ghi nhận: $foodCount lần  
• Công việc/Học tập: $workCount lần
• Nghỉ ngơi/Thiền: $restCount lần

═══ LỊCH SỬ HOẠT ĐỘNG ═══
$actSummary

═══ YÊU CẦU ═══
Hãy tạo kế hoạch chi tiết cho ngày hôm nay bằng tiếng Việt, gồm:

1. 🌅 BUỔI SÁNG (6:00 – 11:00)
   - Gợi ý thức dậy, vận động, ăn sáng phù hợp với thể trạng (BMI $bmi)
   
2. ☀️ BUỔI TRƯA (11:00 – 14:00)  
   - Menu ăn trưa cụ thể (kcal phù hợp với cân nặng/mục tiêu)
   - Thời gian nghỉ tối ưu
   
3. 🌇 BUỔI CHIỀU (14:00 – 18:00)
   - Lịch làm việc/học tập tối ưu dựa trên nghề nghiệp
   - Bài tập hoặc hoạt động thể chất phù hợp
   
4. 🌙 BUỔI TỐI (18:00 – 22:00)
   - Ăn tối lành mạnh
   - Thư giãn và chuẩn bị cho ngày mai
   
5. 💡 LỜI KHUYÊN CÁ NHÂN HÓA
   - 2-3 điểm cần cải thiện dựa trên thống kê 7 ngày qua
   - Khuyến nghị dinh dưỡng theo BMI

Giữ ngắn gọn, súc tích, thực tế và có thể thực hiện ngay.
''';
  }

  String _mockPersonalizedAdvice(UserModel user) {
    final bmi = user.bmi;
    String bmiAdvice = '';
    if (bmi != null) {
      if (bmi < 18.5) {
        bmiAdvice = '⚠️ BMI ${bmi.toStringAsFixed(1)} – cần tăng cường dinh dưỡng, ưu tiên protein và carb lành mạnh.';
      } else if (bmi < 25) {
        bmiAdvice = '✅ BMI ${bmi.toStringAsFixed(1)} – thể trạng lý tưởng! Duy trì chế độ hiện tại.';
      } else if (bmi < 30) {
        bmiAdvice = '🔶 BMI ${bmi.toStringAsFixed(1)} – cần tăng hoạt động cardio và kiểm soát khẩu phần.';
      } else {
        bmiAdvice = '🔴 BMI ${bmi.toStringAsFixed(1)} – ưu tiên giảm cân lành mạnh, tư vấn bác sĩ dinh dưỡng.';
      }
    }

    return '''
🌅 BUỔI SÁNG (6:00 – 11:00)
• 6:00 – Thức dậy, uống 300ml nước ấm
• 6:15 – Kéo giãn cơ 10 phút hoặc yoga nhẹ
• 7:00 – Ăn sáng: ${user.gender == 'Nữ' ? 'Cháo yến mạch + hoa quả (350 kcal)' : 'Bánh mì trứng + sữa ít đường (450 kcal)'}
• 8:00 – Bắt đầu công việc / học tập chính

☀️ BUỔI TRƯA (11:00 – 14:00)
• 12:00 – Ăn trưa: Cơm gạo lứt + ức gà + rau xanh luộc (550 kcal)
• 12:45 – Đi bộ nhẹ 15 phút sau ăn
• 13:00 – Nghỉ trưa 30 phút (không nên quá 45 phút)

🌇 BUỔI CHIỀU (14:00 – 18:00)
• 14:00 – Tiếp tục ${user.occupation ?? 'công việc'} với kỹ thuật Pomodoro
• 15:30 – Uống trà xanh, ăn nhẹ hoa quả
• 17:00 – ${bmi != null && bmi > 25 ? '🏃 Cardio 45 phút (chạy bộ hoặc đạp xe)' : '🏋️ Tập thể lực 45-60 phút'}

🌙 BUỔI TỐI (18:00 – 22:00)
• 19:00 – Ăn tối nhẹ: ${user.gender == 'Nữ' ? 'Súp + salad (350 kcal)' : 'Cơm + cá hấp + canh (500 kcal)'}
• 20:00 – Đọc sách hoặc thư giãn
• 21:30 – Thiền 10 phút, hạn chế điện thoại
• 22:00 – Ngủ đủ 7-8 tiếng

💡 LỜI KHUYÊN CÁ NHÂN HÓA
$bmiAdvice
• Uống đủ ${user.gender == 'Nữ' ? '1.8L' : '2.5L'} nước mỗi ngày
• Dành ít nhất 30 phút/ngày cho hoạt động thể chất
''';
  }

  String _mockSimpleAdvice(String username) {
    return '''
Xin chào $username! Dựa trên lịch trình của bạn hôm nay:

✅ Điểm tốt: Bạn đã có lịch trình khá rõ ràng. Hãy duy trì thói quen này!

💧 Dinh dưỡng: Nhớ uống đủ 2 lít nước và không bỏ bữa sáng.

🏃 Vận động: Thêm ít nhất 30 phút đi bộ hoặc kéo giãn cơ vào buổi chiều.

😴 Nghỉ ngơi: Cố gắng ngủ trước 23:00 và dậy đúng giờ để cơ thể hồi phục tốt nhất.

🎯 Mục tiêu: Hoàn thành các thử thách hôm nay để tích điểm và leo hạng!
''';
  }
}
