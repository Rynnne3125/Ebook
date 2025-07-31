import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';

class AIServerManager {
  static Process? _serverProcess;
  static bool _isServerRunning = false;
  static Timer? _healthCheckTimer;

  static Future<bool> startServer() async {
    if (_isServerRunning) return true;

    try {
      // Chỉ khởi động server trên desktop platforms
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        print('🚀 Starting AI Server...');
        
        // Tìm file assistant.py
        final scriptPath = await _findAssistantScript();
        if (scriptPath == null) {
          print('❌ assistant.py not found');
          return false;
        }

        // Khởi động Python server
        _serverProcess = await Process.start(
          'python',
          [scriptPath],
          workingDirectory: Directory.current.path,
        );

        // Lắng nghe output
        _serverProcess!.stdout.transform(SystemEncoding().decoder).listen((data) {
          print('AI Server: $data');
        });

        _serverProcess!.stderr.transform(SystemEncoding().decoder).listen((data) {
          print('AI Server Error: $data');
        });

        // Đợi server khởi động
        await Future.delayed(const Duration(seconds: 3));
        
        // Kiểm tra health
        final isHealthy = await AIService.checkHealth();
        if (isHealthy) {
          _isServerRunning = true;
          _startHealthCheck();
          print('✅ AI Server started successfully');
          return true;
        } else {
          print('❌ AI Server failed to start');
          await stopServer();
          return false;
        }
      } else {
        // Trên web/mobile, chỉ kiểm tra server có sẵn
        final isHealthy = await AIService.checkHealth();
        if (isHealthy) {
          _isServerRunning = true;
          _startHealthCheck();
          print('✅ AI Server already running');
          return true;
        } else {
          print('⚠️ AI Server not available. Please start assistant.py manually');
          return false;
        }
      }
    } catch (e) {
      print('❌ Failed to start AI Server: $e');
      return false;
    }
  }

  static Future<String?> _findAssistantScript() async {
    final possiblePaths = [
      'assistant.py',
      '../assistant.py',
      '../../assistant.py',
      'scripts/assistant.py',
      'python/assistant.py',
    ];

    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        return file.absolute.path;
      }
    }
    return null;
  }

  static void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) async {
        final isHealthy = await AIService.checkHealth();
        if (!isHealthy) {
          print('⚠️ AI Server health check failed');
          _isServerRunning = false;
          timer.cancel();
        }
      },
    );
  }

  static Future<void> stopServer() async {
    _healthCheckTimer?.cancel();
    
    if (_serverProcess != null) {
      print('🛑 Stopping AI Server...');
      _serverProcess!.kill();
      _serverProcess = null;
    }
    
    _isServerRunning = false;
    print('✅ AI Server stopped');
  }

  static bool get isRunning => _isServerRunning;

  static Future<bool> restartServer() async {
    await stopServer();
    await Future.delayed(const Duration(seconds: 2));
    return await startServer();
  }
}