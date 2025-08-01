import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/ai_service.dart';
import 'package:just_audio/just_audio.dart';
import '../services/ai_server_manager.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class AITeachingAssistant extends StatefulWidget {
  final double width;
  final double height;
  final bool isMinimized;
  final VoidCallback? onToggle;
  final String? currentPageContent;
  final Function(String)? onReadPage;

  // Voice control parameters
  final bool? isAutoReading;
  final bool? isPlaying;
  final bool? isPaused;
  final VoidCallback? onToggleAutoReading;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNextPage;
  final VoidCallback? onPauseTeaching; // Pause teaching voice when user interacts
  final VoidCallback? onResumeTeaching; // Resume teaching voice after user interaction
  final VoidCallback? onPreviousPage;

  const AITeachingAssistant({
    super.key,
    this.width = 300,
    this.height = 400,
    this.isMinimized = false,
    this.onToggle,
    this.currentPageContent,
    this.onReadPage,
    this.isAutoReading,
    this.isPlaying,
    this.isPaused,
    this.onToggleAutoReading,
    this.onPlayPause,
    this.onNextPage,
    this.onPauseTeaching,
    this.onResumeTeaching,
    this.onPreviousPage,
  });

  @override
  State<AITeachingAssistant> createState() => _AITeachingAssistantState();
}

class _AITeachingAssistantState extends State<AITeachingAssistant>
    with TickerProviderStateMixin {
  late AnimationController _avatarController;
  late AnimationController _gestureController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _gestureAnimation;
  
  FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;
  bool isListening = false;
  String currentMessage = "Xin chào! Tôi là trợ giảng ảo của bạn. Hãy hỏi tôi về nội dung bài học!";

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAIConnected = false;
  bool _isProcessing = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTTS();
    _initializeSpeech();
    _checkAIConnection();
    _addMessage("assistant", currentMessage);
  }

  void _checkAIConnection() async {
    setState(() {
      _isProcessing = true;
    });

    // Thử kết nối trước
    bool isConnected = await AIService.checkHealth();
    
    // Nếu không kết nối được, thử khởi động server
    if (!isConnected) {
      print('🔄 Attempting to start AI Server...');
      final serverStarted = await AIServerManager.startServer();
      if (serverStarted) {
        // Đợi một chút rồi kiểm tra lại
        await Future.delayed(const Duration(seconds: 2));
        isConnected = await AIService.checkHealth();
      }
    }

    setState(() {
      _isAIConnected = isConnected;
      _isProcessing = false;
    });
    
    if (isConnected) {
      _addMessage("system", "✅ Đã kết nối với AI Server");
    } else {
      _addMessage("system", "⚠️ Không thể kết nối AI. Vui lòng chạy: python assistant.py");
    }
  }

  void _initializeAnimations() {
    _avatarController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _gestureController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _avatarController,
      curve: Curves.easeInOut,
    ));
    
    _gestureAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gestureController,
      curve: Curves.elasticOut,
    ));
  }

  void _initializeTTS() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setSpeechRate(0.8);
    await flutterTts.setVolume(0.8);
    await flutterTts.setPitch(1.0);
    
    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
      _gestureController.repeat(reverse: true);
    });
    
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
      _gestureController.stop();
    });
  }

  void _initializeSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        print('Microphone permission denied');
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            isListening = false;
          });
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              isListening = false;
            });
          }
        },
      );
      
      if (_speechEnabled) {
        print('✅ Speech recognition initialized');
      } else {
        print('❌ Speech recognition failed to initialize');
      }
    } catch (e) {
      print('Speech initialization error: $e');
      _speechEnabled = false;
    }
  }

  void _addMessage(String type, String content) {
    setState(() {
      _messages.add({
        'type': type,
        'content': content,
        'timestamp': DateTime.now(),
      });
    });
  }

  void _speak(String text) async {
    if (isSpeaking) {
      await flutterTts.stop();
    }
    await flutterTts.speak(text);
  }

  void _readCurrentPage() async {
    if (widget.currentPageContent == null || widget.currentPageContent!.isEmpty) {
      _speak("Không có nội dung để đọc trên trang này.");
      _addMessage("assistant", "Không có nội dung để đọc trên trang này.");
      return;
    }

    if (!_isAIConnected) {
      _speak("Vui lòng khởi động AI server trước.");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await AIService.readPage(
        pageContent: widget.currentPageContent!,
      );
      
      final reply = response['reply'] ?? 'Không thể đọc trang';
      final audioBase64 = response['audio'];
      
      _addMessage("assistant", "Đang đọc nội dung trang...");
      
      // Phát audio
      if (audioBase64 != null) {
        await _playAudioFromBase64(audioBase64);
      } else {
        _speak(reply);
      }
      
    } catch (e) {
      _addMessage("assistant", "Không thể đọc nội dung trang này.");
      print('Read page error: $e');
    }
    
    setState(() {
      _isProcessing = false;
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isProcessing) return;

    // Pause teaching voice when user sends message
    if (widget.onPauseTeaching != null) {
      widget.onPauseTeaching!();
    }

    setState(() {
      _isProcessing = true;
    });

    _addMessage("user", message);
    _messageController.clear();
    
    if (!_isAIConnected) {
      _addMessage("assistant", "Vui lòng khởi động AI server trước.");
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // Gửi tin nhắn đến AI
      final response = await AIService.sendMessage(
        message: message,
        pageContent: widget.currentPageContent,
      );
      
      final reply = response['reply'] ?? 'Không có phản hồi';
      final audioBase64 = response['audio'];
      
      _addMessage("assistant", reply);
      
      // Phát audio nếu có
      if (audioBase64 != null) {
        await _playAudioFromBase64(audioBase64);
      } else {
        // Fallback to TTS
        _speak(reply);
      }
      
    } catch (e) {
      _addMessage("assistant", "Xin lỗi, tôi đang gặp sự cố. Vui lòng thử lại.");
      print('Send message error: $e');
    }
    
    setState(() {
      _isProcessing = false;
    });

    // Resume teaching will be handled by audio completion listener
  }

  Future<void> _playAudioFromBase64(String audioBase64) async {
    try {
      setState(() {
        isSpeaking = true;
      });
      _gestureController.repeat(reverse: true);
      
      // Tạo data URL
      final dataUrl = 'data:audio/mp3;base64,$audioBase64';
      
      // Set audio source
      await _audioPlayer.setUrl(dataUrl);
      
      // Play audio
      await _audioPlayer.play();
      
      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() {
            isSpeaking = false;
          });
          _gestureController.stop();

          // Resume teaching voice after AI response audio finishes
          if (widget.onResumeTeaching != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!isSpeaking && mounted) {
                widget.onResumeTeaching!();
              }
            });
          }
        }
      });
      
    } catch (e) {
      print('Audio playback error: $e');
      setState(() {
        isSpeaking = false;
      });
      _gestureController.stop();
      
      // Fallback to TTS
      _speak("Có lỗi phát audio, tôi sẽ dùng giọng nói mặc định.");
    }
  }

  void _toggleVoiceInput() async {
    if (!_speechEnabled) {
      _addMessage("system", "⚠️ Microphone không khả dụng");
      return;
    }

    if (isListening) {
      // Stop listening
      await _speechToText.stop();
      setState(() {
        isListening = false;
      });
    } else {
      // Pause teaching voice when user starts voice input
      if (widget.onPauseTeaching != null) {
        widget.onPauseTeaching!();
      }

      // Start listening
      setState(() {
        isListening = true;
      });

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognizedText = result.recognizedWords;
            if (recognizedText.isNotEmpty) {
              _messageController.text = recognizedText;
              _sendMessage();
            }
          }
        },
        localeId: 'vi_VN', // Vietnamese
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  @override
  void dispose() {
    _avatarController.dispose();
    _gestureController.dispose();
    _messageController.dispose();
    flutterTts.stop();
    _audioPlayer.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Đảm bảo widget có thể nhận touch events
      child: Container(
        width: widget.isMinimized ? 60 : widget.width,
        height: widget.isMinimized ? 60 : widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isAIConnected 
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [Colors.grey.shade600, Colors.grey.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: widget.isMinimized ? _buildMinimizedView() : _buildFullView(),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_bounceAnimation.value),
            child: const Center(
              child: Icon(
                Icons.school,
                color: Colors.white,
                size: 30,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullView() {
    return Material( // Thêm Material wrapper
      color: Colors.transparent,
      child: Column(
        children: [
          // Header với status
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Trợ Giảng AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isAIConnected ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isAIConnected ? "Gemini AI" : "Offline",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isProcessing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                IconButton(
                  onPressed: widget.onToggle,
                  icon: const Icon(Icons.minimize, color: Colors.white),
                  splashColor: Colors.white24,
                ),
              ],
            ),
          ),
          
          // Quick Actions
          _buildQuickActions(),
          
          // Messages
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Voice button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isProcessing ? null : _toggleVoiceInput,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isListening 
                          ? Colors.red.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: isListening ? Colors.red : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isProcessing,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isProcessing ? "Đang xử lý..." : "Hỏi về bài học...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Send button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isProcessing ? null : _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isProcessing ? Icons.hourglass_empty : Icons.send,
                        color: _isProcessing ? Colors.white54 : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_bounceAnimation.value),
          child: AnimatedBuilder(
            animation: _gestureAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_gestureAnimation.value * 0.1),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isSpeaking ? Icons.record_voice_over : Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        // Voice Controls Row
        if (widget.isAutoReading != null)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildQuickAction(
                  icon: widget.isAutoReading! ? Icons.auto_stories : Icons.auto_stories_outlined,
                  label: "Auto",
                  onTap: widget.onToggleAutoReading,
                  isActive: widget.isAutoReading!,
                ),
                _buildQuickAction(
                  icon: widget.isPaused! ? Icons.play_arrow : Icons.pause,
                  label: widget.isPaused! ? "Play" : "Pause",
                  onTap: widget.onPlayPause,
                  isActive: widget.isPlaying!,
                ),
                _buildQuickAction(
                  icon: Icons.skip_previous,
                  label: "Prev",
                  onTap: widget.onPreviousPage,
                ),
                _buildQuickAction(
                  icon: Icons.skip_next,
                  label: "Next",
                  onTap: widget.onNextPage,
                ),
              ],
            ),
          ),

        // Original Actions Row
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _buildQuickAction(
                icon: Icons.refresh,
                label: "Kết nối",
                onTap: _isProcessing ? null : _checkAIConnection,
              ),
              _buildQuickAction(
                icon: Icons.restart_alt,
                label: "Restart",
                onTap: _isProcessing ? null : _restartAIServer,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.white.withOpacity(onTap != null ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: Colors.blue.withOpacity(0.5), width: 1)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  color: onTap != null ? Colors.white : Colors.white54, 
                  size: 16
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: onTap != null ? Colors.white : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['type'] == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const Icon(Icons.school, color: Colors.white, size: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isUser 
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message['content'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const Icon(Icons.person, color: Colors.white, size: 16),
          ],
        ],
      ),
    );
  }

  void _restartAIServer() async {
    setState(() {
      _isProcessing = true;
    });

    _addMessage("system", "🔄 Đang khởi động lại AI Server...");
    
    final restarted = await AIServerManager.restartServer();
    
    setState(() {
      _isAIConnected = restarted;
      _isProcessing = false;
    });

    if (restarted) {
      _addMessage("system", "✅ AI Server đã khởi động lại thành công");
    } else {
      _addMessage("system", "❌ Không thể khởi động AI Server");
    }
  }
}





