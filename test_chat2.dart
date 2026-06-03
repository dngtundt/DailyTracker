import 'dart:convert';
import 'dart:io';

void main() async {
  final prompt = 'Xin chào';

  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyARAJ86vdu9OPs1q3ImcX2_6LDbkWq7T8U');
  final req = await HttpClient().postUrl(url);
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode({
    'contents': [{'parts': [{'text': prompt}]}],
    'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 4096},
  }));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  print('Status: ${resp.statusCode}');
  print('Body: $body');
}
