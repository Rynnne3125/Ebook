import 'dart:io';
import 'dart:async';

class ServerManager {
  static Process? _assistantProcess;
  static Process? _appProcess;
  static bool _serversStarted = false;

  static Future<bool> startServers() async {
    if (_serversStarted) {
      print('🔄 Servers already started');
      return true;
    }

    try {
      print('🚀 Starting Python AI servers...');

      // Check if Python is available
      final pythonCheck = await Process.run('python', ['--version']);
      if (pythonCheck.exitCode != 0) {
        print('❌ Python not found, trying python3...');
        final python3Check = await Process.run('python3', ['--version']);
        if (python3Check.exitCode != 0) {
          print('❌ Python3 not found. Please install Python.');
          return false;
        }
      }

      // Install dependencies
      print('📦 Installing Python dependencies...');
      final pipInstall = await Process.run('pip', [
        'install', 
        'flask', 
        'flask-cors', 
        'edge-tts', 
        'google-generativeai', 
        'python-dotenv', 
        'requests'
      ]);
      
      if (pipInstall.exitCode != 0) {
        print('⚠️ Pip install failed, trying pip3...');
        await Process.run('pip3', [
          'install', 
          'flask', 
          'flask-cors', 
          'edge-tts', 
          'google-generativeai', 
          'python-dotenv', 
          'requests'
        ]);
      }

      // Start integrated backend (backend/app.py)
      print('🤖 Starting integrated backend server...');
      _appProcess = await Process.start(
        'python',
        ['backend/app.py'],
        workingDirectory: Directory.current.path,
      );

      // Listen to backend output
      _appProcess!.stdout.listen((data) {
        print('Backend: ${String.fromCharCodes(data)}');
      });

      _appProcess!.stderr.listen((data) {
        print('Backend Error: ${String.fromCharCodes(data)}');
      });

      // Wait for backend to fully start
      await Future.delayed(const Duration(seconds: 8));

      _serversStarted = true;
      print('✅ Integrated backend started successfully!');
      return true;

    } catch (e) {
      print('❌ Error starting backend: $e');
      return false;
    }
  }

  static Future<void> stopServers() async {
    print('🛑 Stopping backend server...');

    if (_appProcess != null) {
      _appProcess!.kill();
      _appProcess = null;
    }
    
    if (_appProcess != null) {
      _appProcess!.kill();
      _appProcess = null;
    }
    
    _serversStarted = false;
    print('✅ Servers stopped');
  }

  static bool get isStarted => _serversStarted;
}
