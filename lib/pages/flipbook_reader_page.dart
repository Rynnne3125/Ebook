import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../utils/responsive_utils.dart';
import '../widgets/heyzine_flipbook_widget.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../models/flipbook_model.dart';
import '../widgets/ai_teaching_assistant.dart';
import '../models/teaching_script_model.dart';

class FlipBookReaderPage extends StatefulWidget {
  final String bookId;
  final FlipBookModel? book;

  const FlipBookReaderPage({
    super.key,
    required this.bookId,
    this.book,
  });

  @override
  State<FlipBookReaderPage> createState() => _FlipBookReaderPageState();
}

class _FlipBookReaderPageState extends State<FlipBookReaderPage>
    with TickerProviderStateMixin {
  late AnimationController _pageController;
  late Animation<double> _pageAnimation;
  
  final FirestoreService _firestoreService = FirestoreService();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  FlipBookModel? book;
  bool isLoading = true;
  int currentPage = 0;
  bool useHeyzine = false;
  bool showAIObserver = false;

  // Thêm variables cho AI Assistant
  bool _showAIAssistant = true;

  // Teaching scripts data
  EBook? _ebookData;
  List<BookPage> _teachingPages = [];
  int _currentPageNumber = 1;
  bool _isPlayingScript = false;
  bool _autoReadingEnabled = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTTS();
    _loadBook();
  }

  void _initializeAnimations() {
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: Curves.easeInOut,
    ));

    _pageController.forward();
  }

  Future<void> _initializeTTS() async {
    try {
      // Configure TTS settings
      await _flutterTts.setLanguage("vi-VN"); // Vietnamese
      await _flutterTts.setSpeechRate(0.8); // Slightly slower for teaching
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set completion handler for auto page advancement
      _flutterTts.setCompletionHandler(() {
        print('🎤 TTS completed');
        setState(() {
          _isPlayingScript = false;
        });

        // Auto advance to next page if auto-reading is enabled
        if (_autoReadingEnabled && !_isPaused) {
          Future.delayed(const Duration(seconds: 1), () {
            _goToNextPage();
          });
        }
      });

      print('✅ TTS initialized successfully');
    } catch (e) {
      print('❌ TTS initialization error: $e');
    }
  }

  Future<void> _loadBook() async {
    try {
      if (widget.book != null) {
        book = widget.book;
        await _firestoreService.incrementViewCount(book!.id);
      } else {
        book = await _firestoreService.getBookWithPages(widget.bookId);
        if (book != null) {
          await _firestoreService.incrementViewCount(book!.id);
        }
      }
      
      setState(() {
        isLoading = false;
        // Xóa useHeyzine, luôn dùng custom view
      });

      // Try to load teaching scripts if available
      await _loadTeachingScripts();
    } catch (e) {
      print('Error loading book: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTeachingScripts() async {
    try {
      print('📚 Loading teaching scripts for book: ${book?.title}');
      print('🔍 Book ID: ${book?.id}');

      if (book?.id == null) {
        print('❌ Book ID is null, cannot load teaching scripts');
        return;
      }

      // Load EBook data with teaching scripts from Firestore
      final ebookDoc = await _firestoreService.getEBookWithScripts(book!.id);

      if (ebookDoc != null && ebookDoc.pages.isNotEmpty) {
        setState(() {
          _ebookData = ebookDoc;
          _teachingPages = ebookDoc.pages;
        });

        print('✅ Loaded ${_teachingPages.length} pages with teaching scripts');

        // Auto-start reading when flipbook loads
        if (_teachingPages.isNotEmpty && _autoReadingEnabled) {
          _startAutoReading();
        }
      } else {
        print('⚠️ No teaching scripts found for this book. This might be a sample book without AI-generated content.');
      }

    } catch (e) {
      print('Error loading teaching scripts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (book == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ResponsiveUtils.isMobile(context)
                ? _buildMobileLayout()
                : _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Phần hiển thị sách (70% màn hình)
        Expanded(
          flex: 7,
          child: _buildHeyzineView(),
        ),
        // Phần AI Assistant (30% màn hình)
        if (_showAIAssistant)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: AITeachingAssistant(
                width: double.infinity,
                height: double.infinity,
                isMinimized: false,
                onToggle: _toggleAIAssistant,
                currentPageContent: _getCurrentPageContent(),
                onReadPage: (content) {
                  _playCurrentPageScript();
                },
                // Pass voice control functions
                isAutoReading: _autoReadingEnabled,
                isPlaying: _isPlayingScript,
                isPaused: _isPaused,
                onToggleAutoReading: _toggleAutoReading,
                onPlayPause: _togglePlayPause,
                onNextPage: _goToNextPage,
                onPreviousPage: _goToPreviousPage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Phần hiển thị sách (70% màn hình)
        Expanded(
          flex: 7,
          child: _buildHeyzineView(),
        ),
        // Phần AI Assistant (30% màn hình)
        if (_showAIAssistant)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: AITeachingAssistant(
                width: double.infinity,
                height: double.infinity,
                isMinimized: false,
                onToggle: _toggleAIAssistant,
                currentPageContent: _getCurrentPageContent(),
                onReadPage: (content) {
                  _playCurrentPageScript();
                },
                // Pass voice control functions
                isAutoReading: _autoReadingEnabled,
                isPlaying: _isPlayingScript,
                isPaused: _isPaused,
                onToggleAutoReading: _toggleAutoReading,
                onPlayPause: _togglePlayPause,
                onNextPage: _goToNextPage,
                onPreviousPage: _goToPreviousPage,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0a0e27),
            const Color(0xFF0a0e27).withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${book!.viewCount} lượt xem',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Toggle between Heyzine and custom
          // if (book!.heyzineUrl != null)
          //   IconButton(
          //     onPressed: () {
          //       setState(() {
          //         useHeyzine = !useHeyzine;
          //       });
          //     },
          //     icon: Icon(
          //       useHeyzine ? Icons.view_module : Icons.web,
          //       color: Colors.white,
          //     ),
          //   ),
          
          // AI Observer toggle
          _buildAIToggle(),
        ],
      ),
    );
  }

  Widget _buildAIToggle() {
    return IconButton(
      onPressed: () {
        setState(() {
          _showAIAssistant = !_showAIAssistant;
        });
      },
      icon: Icon(
        _showAIAssistant ? Icons.smart_toy : Icons.smart_toy_outlined,
        color: _showAIAssistant ? const Color(0xFF667eea) : Colors.white,
      ),
      tooltip: _showAIAssistant ? 'Ẩn AI Assistant' : 'Hiện AI Assistant',
    );
  }

  Widget _buildHeyzineView() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: HeyzineFlipbookWidget(
          heyzineUrl: book!.heyzineUrl!,
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCustomBookView() {
    if (book!.pages.isEmpty) {
      return _buildEmptyPagesView();
    }

    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _pageAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (0.05 * _pageAnimation.value),
                  child: Opacity(
                    opacity: _pageAnimation.value,
                    child: _buildPageContent(isMobile),
                  ),
                );
              },
            ),
          ),
          _buildNavigationControls(isMobile),
        ],
      ),
    );
  }

  Widget _buildEmptyPagesView() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Color(0xFF667eea),
            ),
            SizedBox(height: 16),
            Text(
              'Nội dung đang được cập nhật',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2d3561),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vui lòng quay lại sau',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667eea),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(bool isMobile) {
    final page = book!.pages[currentPage];
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 40),
      child: page.isCover 
          ? _buildCoverPageLayout(page, isMobile)
          : _buildRegularPageLayout(page, isMobile),
    );
  }

  Widget _buildCoverPageLayout(FlipBookPageModel page, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: EdgeInsets.all(isMobile ? 30 : 50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: isMobile ? 60 : 80,
            color: Colors.white,
          ),
          SizedBox(height: isMobile ? 20 : 30),
          Text(
            page.title,
            style: TextStyle(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Text(
            page.content,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegularPageLayout(FlipBookPageModel page, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Trang ${page.pageNumber}',
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: const Color(0xFF667eea),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        Text(
          page.title,
          style: TextStyle(
            fontSize: isMobile ? 20.0 : 28.0,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2d3561),
            height: 1.2,
          ),
        ),
        
        SizedBox(height: isMobile ? 16 : 24),
        
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              page.content,
              style: TextStyle(
                fontSize: isMobile ? 14.0 : 16.0,
                color: const Color(0xFF2d3561),
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationControls(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0a0e27).withOpacity(0.05),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF667eea).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: currentPage > 0 ? _goToFirstPage : null,
            isMobile: isMobile,
          ),
          _buildControlButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 0 ? _previousPage : null,
            isMobile: isMobile,
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF667eea).withOpacity(0.3),
              ),
            ),
            child: Text(
              '${currentPage + 1}/${book!.pages.length}',
              style: TextStyle(
                color: const Color(0xFF667eea),
                fontSize: isMobile ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildControlButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < book!.pages.length - 1 ? _nextPage : null,
            isMobile: isMobile,
          ),
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: currentPage < book!.pages.length - 1 ? _goToLastPage : null,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? 40 : 48,
      height: isMobile ? 40 : 48,
      decoration: BoxDecoration(
        color: onPressed != null 
            ? const Color(0xFF667eea).withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: onPressed != null 
              ? const Color(0xFF667eea).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null 
              ? const Color(0xFF667eea)
              : Colors.grey,
          size: isMobile ? 20 : 24,
        ),
      ),
    );
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
      _pageController.reset();
      _pageController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _nextPage() {
    if (currentPage < book!.pages.length - 1) {
      setState(() {
        currentPage++;
      });
      _pageController.reset();
      _pageController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _goToFirstPage() {
    setState(() {
      currentPage = 0;
    });
    _pageController.reset();
    _pageController.forward();
    HapticFeedback.lightImpact();
  }

  void _goToLastPage() {
    setState(() {
      currentPage = book!.pages.length - 1;
    });
    _pageController.reset();
    _pageController.forward();
    HapticFeedback.lightImpact();
  }

  void _onPageChanged(int pageNumber) {
    setState(() {
      _currentPageNumber = pageNumber;
    });

    // Auto-play teaching script for the new page
    _playTeachingScriptForPage(pageNumber);
  }

  Future<void> _playTeachingScriptForPage(int pageNumber) async {
    try {
      if (!_autoReadingEnabled || _isPaused) return;

      // Find teaching script for this page
      final pageData = _teachingPages.firstWhere(
        (page) => page.pageNumber == pageNumber,
        orElse: () => BookPage(pageNumber: pageNumber, content: ''),
      );

      if (pageData.teachingScript != null && !_isPlayingScript) {
        setState(() {
          _isPlayingScript = true;
          _isPaused = false;
        });

        print('🎤 Playing teaching script for page $pageNumber');

        // Send script to AI Assistant for TTS
        final script = pageData.teachingScript!.script;
        print('📖 Script: $script');

        // Use AI Assistant to play the script
        await _playScriptWithAI(script);

        // Auto advance to next page after script finishes
        if (_autoReadingEnabled && !_isPaused && pageNumber < _teachingPages.length) {
          await Future.delayed(const Duration(seconds: 2)); // Brief pause between pages
          _goToNextPage();
        } else {
          setState(() {
            _isPlayingScript = false;
          });
        }
      }
    } catch (e) {
      print('Error playing teaching script: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  Future<void> _playScriptWithAI(String script) async {
    try {
      print('🎤 Calling AI assistant to read script: ${script.substring(0, 50)}...');

      // Call AI assistant to read the teaching script
      final result = await AIService.readTeachingScript(
        script: script,
        pageNumber: _currentPageNumber,
      );

      if (result.containsKey('error')) {
        print('❌ AI assistant error: ${result['error']}');
        setState(() {
          _isPlayingScript = false;
        });
        return;
      }

      // Get audio base64 from AI assistant
      final audioBase64 = result['audio'];
      if (audioBase64 != null) {
        print('🔊 Playing audio from AI assistant...');
        await _playAudioFromBase64(audioBase64);
      } else {
        print('❌ No audio received from AI assistant');
        setState(() {
          _isPlayingScript = false;
        });
      }

    } catch (e) {
      print('❌ Error calling AI assistant: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  Future<void> _playAudioFromBase64(String audioBase64) async {
    try {
      print('🎵 Setting up audio player...');

      // Create data URL for audio
      final dataUrl = 'data:audio/mp3;base64,$audioBase64';

      // Set audio source
      await _audioPlayer.setUrl(dataUrl);

      // Listen for completion to auto advance page
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print('🎵 Audio playback completed');
          setState(() {
            _isPlayingScript = false;
          });

          // Auto advance to next page if enabled
          if (_autoReadingEnabled && !_isPaused) {
            Future.delayed(const Duration(seconds: 1), () {
              _goToNextPage();
            });
          }
        }
      });

      // Play audio
      print('▶️ Starting audio playback...');
      await _audioPlayer.play();

    } catch (e) {
      print('❌ Error playing audio: $e');
      setState(() {
        _isPlayingScript = false;
      });
    }
  }

  void _toggleAIAssistant() {
    setState(() {
      _showAIAssistant = !_showAIAssistant;
    });
  }

  // Auto-reading functions
  void _startAutoReading() {
    if (_teachingPages.isNotEmpty && _autoReadingEnabled) {
      print('🎤 Starting auto-reading from page 1');
      _playTeachingScriptForPage(1);
    }
  }

  void _toggleAutoReading() {
    setState(() {
      _autoReadingEnabled = !_autoReadingEnabled;
    });

    if (_autoReadingEnabled && !_isPlayingScript) {
      _playCurrentPageScript();
    } else if (!_autoReadingEnabled && _isPlayingScript) {
      _stopCurrentScript();
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _pauseCurrentScript();
    } else {
      _resumeCurrentScript();
    }
  }

  void _playCurrentPageScript() {
    if (_autoReadingEnabled && !_isPlayingScript) {
      _playTeachingScriptForPage(_currentPageNumber);
    }
  }

  void _stopCurrentScript() async {
    setState(() {
      _isPlayingScript = false;
      _isPaused = false;
    });
    await _flutterTts.stop();
    await _audioPlayer.stop();
    print('🛑 Audio stopped');
  }

  void _pauseCurrentScript() async {
    await _flutterTts.pause();
    await _audioPlayer.pause();
    print('⏸️ Audio paused');
  }

  void _resumeCurrentScript() async {
    // Resume audio player
    await _audioPlayer.play();
    print('▶️ Audio resumed');
  }

  void _goToNextPage() {
    if (_currentPageNumber < _teachingPages.length) {
      setState(() {
        _currentPageNumber++;
      });
      _onPageChanged(_currentPageNumber);
    }
  }

  void _goToPreviousPage() {
    if (_currentPageNumber > 1) {
      setState(() {
        _currentPageNumber--;
      });
      _onPageChanged(_currentPageNumber);
    }
  }

  String _getCurrentPageContent() {
    if (book == null || currentPage >= book!.pages.length) {
      return "";
    }

    // Giả sử bạn có content text trong page model
    // Thay đổi theo cấu trúc dữ liệu thực tế của bạn
    final page = book!.pages[currentPage];

    // Also check teaching pages
    final teachingPage = _teachingPages.firstWhere(
      (page) => page.pageNumber == _currentPageNumber,
      orElse: () => BookPage(pageNumber: _currentPageNumber, content: ''),
    );

    if (teachingPage.content.isNotEmpty) {
      return teachingPage.content;
    }

    return page.content ?? "Nội dung trang ${currentPage + 1}";
  }

  String _getCurrentTeachingScript() {
    final teachingPage = _teachingPages.firstWhere(
      (page) => page.pageNumber == _currentPageNumber,
      orElse: () => BookPage(pageNumber: _currentPageNumber, content: ''),
    );

    return teachingPage.teachingScript?.script ?? '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flutterTts.stop(); // Stop TTS when disposing
    super.dispose();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang tải sách...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng chờ trong giây lát',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e27),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Không thể tải sách',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sách không tồn tại hoặc đã bị xóa.\nVui lòng kiểm tra lại đường dẫn.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Quay lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                      });
                      _loadBook();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


























