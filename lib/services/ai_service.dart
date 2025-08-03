import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  // Dynamic base URL based on environment
  static String get baseUrl {
    // 1. Check for explicit Render backend URL
    const String? renderUrl = String.fromEnvironment('RENDER_BACKEND_URL');
    if (renderUrl != null && renderUrl.isNotEmpty) {
      print('🌐 Using Render backend: $renderUrl');
      return renderUrl;
    }

    // 2. Check for general backend URL
    const String? backendUrl = String.fromEnvironment('BACKEND_URL');
    if (backendUrl != null && backendUrl.isNotEmpty) {
      print('🔗 Using custom backend: $backendUrl');
      return backendUrl;
    }

    // 3. Web platform - use local backend for testing (Render.com not ready)
    if (kIsWeb) {
      final localUrl = 'http://localhost:5001';
      print('🌐 Web platform - Using local backend: $localUrl');
      return localUrl;
    }

    // 4. Default to Render.com for production
    print('🚀 Using Render.com production backend: https://ebook-backend-ggqr.onrender.com');
    return 'https://ebook-backend-ggqr.onrender.com';
  }
  
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

  static Future<Map<String, dynamic>> readTeachingScript({
    required String script,
    required int pageNumber,
  }) async {
    try {
      print('🎤 Calling AI assistant to read teaching script for page $pageNumber');

      final response = await http.post(
        Uri.parse('$baseUrl/read-teaching-script'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'script': script,
          'pageNumber': pageNumber,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('✅ AI assistant responded with audio for page $pageNumber');
        return result;
      } else {
        throw Exception('Failed to read teaching script: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error calling AI assistant: $e');
      return {'error': e.toString()};
    }
  }
}