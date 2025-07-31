import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'http://localhost:5000';
  
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    String? pageContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'pageContent': pageContent ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Service Error: $e');
      return {
        'reply': 'Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau.',
        'audio': null,
        'error': true,
      };
    }
  }

  static Future<Map<String, dynamic>> readPage({
    required String pageContent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/read-page'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'pageContent': pageContent,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to read page: ${response.statusCode}');
      }
    } catch (e) {
      print('AI Service Error: $e');
      return {
        'reply': 'Không thể đọc nội dung trang này.',
        'audio': null,
        'error': true,
      };
    }
  }

  static Uint8List? decodeAudio(String? audioBase64) {
    if (audioBase64 == null || audioBase64.isEmpty) return null;
    try {
      return base64Decode(audioBase64);
    } catch (e) {
      print('Audio decode error: $e');
      return null;
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}