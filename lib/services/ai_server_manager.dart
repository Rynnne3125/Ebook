import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
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
      // Kiểm tra xem server đã chạy chưa
      print('🔍 Checking if AI Server is already running...');
      final isAlreadyRunning = await AIService.checkHealth();
      if (isAlreadyRunning) {
        _isServerRunning = true;
        _startHealthCheck();
        print('✅ AI Server already running');
        return true;
      }

      // Chỉ khởi động server trên desktop platforms
      if (!kIsWeb) {
        try {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        print('🚀 Starting AI Server...');

        // Tìm file backend/app.py
        final scriptPath = await _findBackendScript();
        if (scriptPath == null) {
          print('❌ backend/app.py not found in current directory');
          print('📁 Current directory: ${Directory.current.path}');
          print('💡 Please ensure backend/app.py exists');
          return false;
        }

        print('📄 Found backend/app.py at: $scriptPath');

        // Thử các lệnh Python khác nhau
        final pythonCommands = ['python', 'python3', 'py'];

        for (final pythonCmd in pythonCommands) {
          try {
            print('🐍 Trying to start with: $pythonCmd');

            // Khởi động Python server
            _serverProcess = await Process.start(
              pythonCmd,
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

            // Đợi server khởi động với thời gian dài hơn
            print('⏳ Waiting for AI Server to start...');
            await Future.delayed(const Duration(seconds: 5));

            // Kiểm tra health nhiều lần
            bool isHealthy = false;
            for (int i = 0; i < 3; i++) {
              isHealthy = await AIService.checkHealth();
              if (isHealthy) break;
              await Future.delayed(const Duration(seconds: 2));
            }

            if (isHealthy) {
              _isServerRunning = true;
              _startHealthCheck();
              print('✅ AI Server started successfully with $pythonCmd');
              return true;
            } else {
              print('❌ AI Server failed health check with $pythonCmd');
              await _killCurrentProcess();
            }
          } catch (e) {
            print('❌ Failed to start with $pythonCmd: $e');
            await _killCurrentProcess();
          }
        }

            print('❌ Failed to start AI Server with any Python command');
            return false;
          }
        } catch (e) {
          print('⚠️ Platform detection failed: $e');
          // Trên web/mobile, chỉ kiểm tra server có sẵn
          print('⚠️ AI Server not available. Please start backend manually');
          print('💡 Run: python backend/app.py');
          return false;
        }
      } else {
        // Trên web, chỉ kiểm tra server có sẵn
        print('🌐 Web platform detected - AI Server should be started manually');
        print('💡 Run: python backend/app.py');
        return false;
      }
    } catch (e) {
      print('❌ Failed to start AI Server: $e');
      return false;
    }

    // Default return for any unhandled case
    return false;
  }

  static Future<void> _killCurrentProcess() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
    }
  }

  static Future<String?> _findBackendScript() async {
    final possiblePaths = [
      'backend/app.py',
      '../backend/app.py',
      '../../backend/app.py',
      'app.py',
      '../app.py',
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