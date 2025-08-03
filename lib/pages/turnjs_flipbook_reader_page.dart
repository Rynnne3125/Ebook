import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../widgets/turnjs_flipbook_widget.dart';
import '../services/turnjs_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../models/flipbook_model.dart';
import '../models/teaching_script_model.dart';
import '../widgets/ai_teaching_assistant.dart';
import 'package:just_audio/just_audio.dart';

class TurnJSFlipbookReaderPage extends StatefulWidget {
  final String bookId;
  final FlipBookModel? book;
  final File? pdfFile; // For direct PDF upload

  const TurnJSFlipbookReaderPage({
    super.key,
    required this.bookId,
    this.book,
    this.pdfFile,
  });

  @override
  State<TurnJSFlipbookReaderPage> createState() => _TurnJSFlipbookReaderPageState();
}

class _TurnJSFlipbookReaderPageState extends State<TurnJSFlipbookReaderPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Flipbook state
  List<Map<String, dynamic>> _flipbookPages = [];
  bool _isLoading = true;
  bool _isConverting = false;
  String _loadingMessage = 'Đang tải...';
  
  // Book data
  FlipBookModel? _book;
  EBook? _ebookData;
  List<BookPage> _teachingPages = [];
  
  // Page tracking
  int _currentPage = 1;
  int _totalPages = 0;
  
  // AI Assistant state
  bool _isPlayingScript = false;
  bool _autoReadingEnabled = true;
  bool _isPaused = false;
  bool _isProcessingPageChange = false;
  bool _showAIAssistant = true;
  
  // Turn.js widget controller
  TurnJSFlipbookWidget? _flipbookWidget;

  @override
  void initState() {
    super.initState();
    _initializeFlipbook();
  }

  Future<void> _initializeFlipbook() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingMessage = 'Đang khởi tạo flipbook...';
      });

      if (widget.pdfFile != null) {
        // Convert PDF file to images
        await _convertPdfToImages();
      } else if (widget.book != null) {
        // Load existing book data
        await _loadExistingBook();
      } else {
        // Load book from Firestore
        await _loadBookFromFirestore();
      }

      // Load teaching scripts
      await _loadTeachingScripts();

    } catch (e) {
      print('❌ Flipbook initialization error: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Lỗi: $e';
      });
    }
  }

  Future<void> _convertPdfToImages() async {
    try {
      setState(() {
        _isConverting = true;
        _loadingMessage = 'Đang chuyển đổi PDF thành hình ảnh...';
      });

      final conversionResult = await TurnJSService.convertPdfToImages(widget.pdfFile!);
      
      if (TurnJSService.isValidConversionResult(conversionResult)) {
        _flipbookPages = TurnJSService.createFlipbookPages(conversionResult);
        _totalPages = _flipbookPages.length;
        
        print('✅ PDF converted: $_totalPages pages');
        
        setState(() {
          _isLoading = false;
          _isConverting = false;
        });
      } else {
        throw Exception('Invalid conversion result');
      }
    } catch (e) {
      print('❌ PDF conversion error: $e');
      setState(() {
        _isLoading = false;
        _isConverting = false;
        _loadingMessage = 'Lỗi chuyển đổi PDF: $e';
      });
    }
  }

  Future<void> _loadExistingBook() async {
    try {
      _book = widget.book;

      // Load EBook data first to get Turn.js pages
      if (_book?.id != null) {
        _ebookData = await _firestoreService.getEBookWithScripts(_book!.id);
      }

      // Check if book has Turn.js pages data from Firestore
      if (_ebookData?.turnJSPages != null && _ebookData!.turnJSPages!.isNotEmpty) {
        _flipbookPages = _ebookData!.turnJSPages!;
        _totalPages = _flipbookPages.length;
        print('✅ Loaded Turn.js pages from Firestore: ${_totalPages} pages');
      } else {
        // No Turn.js data available - need to convert PDF first
        throw Exception('Book needs to be converted to Turn.js format first. Please upload a PDF file instead.');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Load existing book error: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Lỗi tải sách: $e';
      });
    }
  }

  Future<void> _loadBookFromFirestore() async {
    try {
      _book = await _firestoreService.getBookWithPages(widget.bookId);
      
      if (_book != null) {
        await _loadExistingBook();
      } else {
        throw Exception('Book not found');
      }
    } catch (e) {
      print('❌ Load book from Firestore error: $e');
      setState(() {
        _isLoading = false;
        _loadingMessage = 'Lỗi tải sách từ Firestore: $e';
      });
    }
  }

  Future<void> _loadTeachingScripts() async {
    try {
      if (_book?.id == null) return;

      print('📚 Loading teaching scripts for book: ${_book!.id}');

      // Load _ebookData if not already loaded
      if (_ebookData == null) {
        _ebookData = await _firestoreService.getEBookWithScripts(_book!.id);
      }

      if (_ebookData != null && _ebookData!.pages.isNotEmpty) {
        _teachingPages = _ebookData!.pages;
        print('📄 Loaded ${_teachingPages.length} teaching pages');
        
        // Start auto-reading if enabled
        if (_autoReadingEnabled && _teachingPages.isNotEmpty) {
          Future.delayed(const Duration(seconds: 2), () {
            _startAutoReading();
          });
        }
      } else {
        print('⚠️ No teaching scripts found for this book');
      }
    } catch (e) {
      print('❌ Error loading teaching scripts: $e');
    }
  }

  void _onFlipbookReady() {
    print('✅ Turn.js flipbook is ready');
    setState(() {
      _isLoading = false;
    });
  }

  void _onPageChanged(int newPage) {
    if (_isProcessingPageChange) return;
    
    print('📖 Page changed to: $newPage');
    
    setState(() {
      _currentPage = newPage;
      _isProcessingPageChange = true;
    });

    // Stop current audio
    _stopCurrentAudio();

    // Play teaching script for new page
    if (_autoReadingEnabled && !_isPaused) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _playTeachingScriptForPage(newPage);
        setState(() {
          _isProcessingPageChange = false;
        });
      });
    } else {
      setState(() {
        _isProcessingPageChange = false;
      });
    }
  }

  Future<void> _playTeachingScriptForPage(int pageNumber) async {
    try {
      final pageScript = _getTeachingScriptForPage(pageNumber);
      
      if (pageScript != null && pageScript.isNotEmpty) {
        print('🎤 Playing teaching script for page $pageNumber');
        print('📖 Script: ${pageScript.substring(0, pageScript.length > 100 ? 100 : pageScript.length)}...');
        
        setState(() {
          _isPlayingScript = true;
        });

        // Call AI assistant to read the script
        await _callAIAssistantToRead(pageScript, pageNumber);
      } else {
        print('⚠️ No teaching script found for page $pageNumber');
      }
    } catch (e) {
      print('❌ Error playing teaching script: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  String? _getTeachingScriptForPage(int pageNumber) {
    try {
      final page = _teachingPages.firstWhere(
        (p) => p.pageNumber == pageNumber,
        orElse: () => throw Exception('Page not found'),
      );
      return page.content;
    } catch (e) {
      return null;
    }
  }

  Future<void> _callAIAssistantToRead(String script, int pageNumber) async {
    try {
      print('🎤 Calling AI assistant to read teaching script for page $pageNumber');
      
      final response = await AIService.readTeachingScript(
        script: script,
        pageNumber: pageNumber,
      );
      
      if (response['audioBase64'] != null) {
        await _playAudioFromBase64(response['audioBase64']);
      } else {
        print('⚠️ No audio received from AI assistant');
        setState(() {
          _isPlayingScript = false;
        });
      }
    } catch (e) {
      print('❌ AI assistant error: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  Future<void> _playAudioFromBase64(String audioBase64) async {
    try {
      // Decode base64 audio and play
      final audioBytes = base64Decode(audioBase64);
      
      // Create temporary file or use memory stream
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.dataFromBytes(audioBytes, mimeType: 'audio/mpeg'),
        ),
      );
      
      // Set completion handler
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _onAudioCompleted();
        }
      });
      
      await _audioPlayer.play();
      
    } catch (e) {
      print('❌ Audio playback error: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  void _onAudioCompleted() {
    print('🎤 Audio completed');
    setState(() {
      _isPlayingScript = false;
    });

    // Auto advance to next page if auto-reading is enabled
    if (_autoReadingEnabled && !_isPaused && _currentPage < _totalPages) {
      Future.delayed(const Duration(seconds: 1), () {
        _goToNextPage();
      });
    }
  }

  void _stopCurrentAudio() {
    try {
      _audioPlayer.stop();
      setState(() {
        _isPlayingScript = false;
      });
    } catch (e) {
      print('❌ Error stopping audio: $e');
    }
  }

  void _startAutoReading() {
    if (_teachingPages.isNotEmpty && !_isPlayingScript) {
      _playTeachingScriptForPage(_currentPage);
    }
  }

  void _toggleAutoReading() {
    setState(() {
      _autoReadingEnabled = !_autoReadingEnabled;
    });
    
    if (_autoReadingEnabled) {
      _startAutoReading();
    } else {
      _stopCurrentAudio();
    }
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _stopCurrentAudio();
    } else if (_autoReadingEnabled) {
      _startAutoReading();
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && _flipbookWidget != null) {
      // Will be implemented when widget is created
      print('📖 Go to next page: ${_currentPage + 1}');
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && _flipbookWidget != null) {
      // Will be implemented when widget is created
      print('📖 Go to previous page: ${_currentPage - 1}');
    }
  }

  void _goToPage(int pageNumber) {
    if (pageNumber >= 1 && pageNumber <= _totalPages && _flipbookWidget != null) {
      // Will be implemented when widget is created
      print('📖 Go to page: $pageNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_book?.title ?? 'Turn.js FlipBook'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Auto-reading toggle
          IconButton(
            icon: Icon(_autoReadingEnabled ? Icons.auto_stories : Icons.auto_stories_outlined),
            onPressed: _toggleAutoReading,
            tooltip: _autoReadingEnabled ? 'Tắt đọc tự động' : 'Bật đọc tự động',
          ),
          // Pause/Play toggle
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Tiếp tục' : 'Tạm dừng',
          ),
          // AI Assistant toggle
          IconButton(
            icon: Icon(_showAIAssistant ? Icons.smart_toy : Icons.smart_toy_outlined),
            onPressed: () {
              setState(() {
                _showAIAssistant = !_showAIAssistant;
              });
            },
            tooltip: _showAIAssistant ? 'Ẩn AI Assistant' : 'Hiện AI Assistant',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isConverting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_loadingMessage),
            if (_isConverting) ...[
              const SizedBox(height: 16),
              const Text('Quá trình này có thể mất vài phút...'),
            ],
          ],
        ),
      );
    }

    if (_flipbookPages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_loadingMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeFlipbook,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Turn.js Flipbook
        TurnJSFlipbookWidget(
          pages: _flipbookPages,
          onPageChanged: _onPageChanged,
          onReady: _onFlipbookReady,
          initialPage: 1,
        ),
        
        // Page info overlay
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Trang $_currentPage/$_totalPages',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
        
        // Playing indicator
        if (_isPlayingScript)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Đang đọc...', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        
        // AI Teaching Assistant
        if (_showAIAssistant)
          Positioned(
            bottom: 16,
            right: 16,
            child: SizedBox(
              width: 300,
              height: 400,
              child: AITeachingAssistant(
                currentPageContent: _getTeachingScriptForPage(_currentPage),
                onNextPage: _goToNextPage,
                onPreviousPage: _goToPreviousPage,
                isAutoReading: _autoReadingEnabled,
                isPlaying: _isPlayingScript,
                isPaused: _isPaused,
                onToggleAutoReading: _toggleAutoReading,
                onPlayPause: _togglePause,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
