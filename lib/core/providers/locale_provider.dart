import 'package:flutter/foundation.dart';

class LocaleProvider extends ChangeNotifier {
  bool _isVietnamese = true;
  bool get isVietnamese => _isVietnamese;

  void toggleLocale() {
    _isVietnamese = !_isVietnamese;
    notifyListeners();
  }

  String tr(String viText, String enText) => _isVietnamese ? viText : enText;
}
