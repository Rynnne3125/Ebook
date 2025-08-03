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

      // Start assistant.py
      print('🤖 Starting assistant.py server...');
      _assistantProcess = await Process.start(
        'python', 
        ['assistant.py'],
        workingDirectory: Directory.current.path,
      );

      // Listen to assistant.py output
      _assistantProcess!.stdout.listen((data) {
        print('Assistant: ${String.fromCharCodes(data)}');
      });

      _assistantProcess!.stderr.listen((data) {
        print('Assistant Error: ${String.fromCharCodes(data)}');
      });

      // Wait for assistant.py to start
      await Future.delayed(const Duration(seconds: 3));

      // Start app.py
      print('📱 Starting app.py server...');
      _appProcess = await Process.start(
        'python', 
        ['app.py'],
        workingDirectory: Directory.current.path,
      );

      // Listen to app.py output
      _appProcess!.stdout.listen((data) {
        print('App: ${String.fromCharCodes(data)}');
      });

      _appProcess!.stderr.listen((data) {
        print('App Error: ${String.fromCharCodes(data)}');
      });

      // Wait for servers to fully start
      await Future.delayed(const Duration(seconds: 5));

      _serversStarted = true;
      print('✅ Python servers started successfully!');
      return true;

    } catch (e) {
      print('❌ Error starting servers: $e');
      return false;
    }
  }

  static Future<void> stopServers() async {
    print('🛑 Stopping Python servers...');
    
    if (_assistantProcess != null) {
      _assistantProcess!.kill();
      _assistantProcess = null;
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
