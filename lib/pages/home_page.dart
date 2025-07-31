import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book_data.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/book_card.dart';
import '../widgets/floating_particles.dart';
import '../pages/flipbook_reader_page.dart';
import '../models/flipbook_page.dart';
import '../services/firestore_service.dart';
import '../models/flipbook_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _bookInfoController;
  late Animation<double> _heroAnimation;
  late Animation<double> _bookInfoAnimation;
  
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedBookIndex = 0;
  List<FlipBookModel> _featuredBooks = [];
  bool _isLoading = true;
  bool _hasInitializedData = false;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bookInfoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Clamp animation values between 0.0 and 1.0
    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.elasticOut,
    );
    _bookInfoAnimation = CurvedAnimation(
      parent: _bookInfoController,
      curve: Curves.easeOut,
    );

    _heroController.forward();
    _bookInfoController.forward();
    _loadFeaturedBooks();
  }

  void _loadFeaturedBooks() async {
    try {
      // Initialize sample data if not exists (only once)
      await _firestoreService.addSampleChemistryBooks();

      // Listen to featured books stream
      _firestoreService.getFeaturedBooks(limit: 5).listen((books) {
        if (mounted) {
          setState(() {
            _featuredBooks = books;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading featured books: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a0e27),
                  Color(0xFF1a1f3a),
                  Color(0xFF2d1b69),
                ],
              ),
            ),
          ),
          // Floating particles animation
          const FloatingParticles(),
          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF667eea),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            _buildHeroSection(),
                            const SizedBox(height: 40),
                            _buildFeaturedBooksSection(),
                            const SizedBox(height: 40),
                            _buildSubjectsSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/admin');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.admin_panel_settings),
        label: const Text('Admin'),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: ResponsiveUtils.isMobile(context) ? 600 : 700,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.isMobile(context) ? 20 : 60,
        vertical: 40,
      ),
      child: ResponsiveUtils.isDesktop(context) 
          ? _buildDesktopHeroSection()  // Sử dụng desktop version
          : _buildMobileHeroSection(),
    );
  }

  Widget _buildMobileHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Text content
        const Text(
          'Khám Phá Thế Giới\nKiến Thức',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Trải nghiệm học tập tương tác với sách điện tử 3D\nvà công nghệ thực tế ảo tiên tiến',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        // Book slider for mobile
        Expanded(child: _buildBookSlider()),
      ],
    );
  }

  Widget _buildDesktopHeroSection() {
    return Row(
      children: [
        // Left side - Text content
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Khám Phá Thế Giới\nKiến Thức',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Trải nghiệm học tập tương tác với sách điện tử 3D\nvà công nghệ thực tế ảo tiên tiến',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Bắt Đầu Học',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tìm Hiểu Thêm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Right side - Book showcase
        Expanded(
          flex: 2,
          child: _featuredBooks.isNotEmpty
              ? AnimatedBuilder(
                  animation: _bookInfoAnimation,
                  builder: (context, child) {
                    final clampedOpacity = _bookInfoAnimation.value.clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(50 * (1 - _bookInfoAnimation.value), 0),
                      child: Opacity(
                        opacity: clampedOpacity,
                        child: Container(
                          height: 350,
                          child: PageView.builder(
                            itemCount: _featuredBooks.length,
                            onPageChanged: (index) {
                              setState(() {
                                _selectedBookIndex = index;
                              });
                              _bookInfoController.reset();
                              _bookInfoController.forward();
                              HapticFeedback.lightImpact();
                            },
                            itemBuilder: (context, index) {
                              final book = _featuredBooks[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                child: GestureDetector(
                                  onTap: () => _openBookReader(book),
                                  child: _buildEnhancedBookCard(book, index),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                )
              : Container(),
        ),
      ],
    );
  }

  Widget _buildBookSlider() {
    if (_featuredBooks.isEmpty) {
      return const Center(
        child: Text(
          'Đang tải sách...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _bookInfoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - _bookInfoAnimation.value), 0),
          child: Opacity(
            opacity: _bookInfoAnimation.value,
            child: Container(
              height: ResponsiveUtils.isMobile(context) ? 280 : 350,
              child: PageView.builder(
                itemCount: _featuredBooks.length,
                onPageChanged: (index) {
                  setState(() {
                    _selectedBookIndex = index;
                  });
                  // Restart animation for smooth transition
                  _bookInfoController.reset();
                  _bookInfoController.forward();
                  HapticFeedback.lightImpact();
                },
                itemBuilder: (context, index) {
                  final book = _featuredBooks[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      onTap: () => _openBookReader(book),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        child: BookCard(
                          book: BookData(
                            title: book.title,
                            image: book.coverImageUrl ?? '',
                            rating: book.rating,
                          ),
                          isSelected: index == _selectedBookIndex,
                          onTap: () => _openBookReader(book),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedBookCard(FlipBookModel book, int index) {
    final isSelected = index == _selectedBookIndex;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isSelected ? 0 : 0.05)
        ..scale(isSelected ? 1.0 : 0.95),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getBookColors(index),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getBookColors(index)[0].withOpacity(isSelected ? 0.4 : 0.2),
            blurRadius: isSelected ? 30 : 15,
            spreadRadius: isSelected ? 8 : 3,
            offset: Offset(0, isSelected ? 15 : 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and rating
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Book illustration
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Book title
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 8),
            
            // Subject
            Text(
              book.subject ?? 'Hóa học',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getBookColors(int index) {
    final colorSets = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFFa8edea), const Color(0xFFfed6e3)],
    ];
    return colorSets[index % colorSets.length];
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildFeaturedBooksSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.isMobile(context) ? 20 : 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sách Nổi Bật',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem thêm',
                  style: TextStyle(
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Sử dụng responsive layout
          ResponsiveUtils.isDesktop(context)
              ? _buildDesktopFeaturedSection(_featuredBooks)
              : _buildMobileFeaturedSection(),
        ],
      ),
    );
  }

  Widget _buildMobileFeaturedSection() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredBooks.length,
        itemBuilder: (context, index) {
          final book = _featuredBooks[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openBookReader(book),
              child: _buildEnhancedBookCard(book, index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopFeaturedSection(List<FlipBookModel> books) {
    return SizedBox(
      height: 400,
      child: Row(
        children: [
          // Left side - Enhanced Book Info (thiết kế mới chuyên nghiệp)
          Expanded(
            flex: 3,
            child: _buildEnhancedBookInfo(books[_selectedBookIndex]),
          ),
          const SizedBox(width: 30),
          // Right side - Book Slider (giống style book info cũ)
          Expanded(
            flex: 2,
            child: _buildProfessionalBookSlider(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedBookInfo(FlipBookModel book) {
    return AnimatedBuilder(
      animation: _bookInfoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-50 * (1 - _bookInfoAnimation.value), 0),
          child: Opacity(
            opacity: _bookInfoAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getBookColors(_selectedBookIndex),
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _getBookColors(_selectedBookIndex)[0].withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header với subject và rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          book.subject ?? 'Hóa học',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < book.rating.floor() ? Icons.star : Icons.star_border,
                              color: Colors.white,
                              size: 18,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            book.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Expanded(
                    child: Text(
                      book.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats
                  Row(
                    children: [
                      _buildStatItem(Icons.visibility, _formatNumber(book.viewCount), 'Lượt xem'),
                      const SizedBox(width: 32),
                      _buildStatItem(Icons.bookmark, _formatNumber(book.bookmarkCount), 'Đánh dấu'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openBookReader(book),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _getBookColors(_selectedBookIndex)[0],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Đọc Ngay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.white.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalBookSlider() {
    return AnimatedBuilder(
      animation: _bookInfoAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - _bookInfoAnimation.value), 0),
          child: Opacity(
            opacity: _bookInfoAnimation.value,
            child: Column(
              children: [
                // Book cards container
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getBookColors(_selectedBookIndex),
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getBookColors(_selectedBookIndex)[0].withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sách Khác',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_selectedBookIndex + 1}/${_featuredBooks.length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Book preview
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.menu_book,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _featuredBooks[_selectedBookIndex].title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Navigation controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous button
                    IconButton(
                      onPressed: _selectedBookIndex > 0 ? _previousSlide : null,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: _selectedBookIndex > 0 ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Page indicators
                    Row(
                      children: List.generate(_featuredBooks.length, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBookIndex = index;
                            });
                            _bookInfoController.reset();
                            _bookInfoController.forward();
                            HapticFeedback.lightImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _selectedBookIndex ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == _selectedBookIndex 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Next button
                    IconButton(
                      onPressed: _selectedBookIndex < _featuredBooks.length - 1 ? _nextSlide : null,
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: _selectedBookIndex < _featuredBooks.length - 1 ? Colors.white : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsSection() {
    final subjects = [
      {'name': 'Hóa Học', 'icon': Icons.science, 'color': const Color(0xFF667eea)},
      {'name': 'Vật Lý', 'icon': Icons.flash_on, 'color': const Color(0xFF4facfe)},
      {'name': 'Toán Học', 'icon': Icons.calculate, 'color': const Color(0xFF43e97b)},
      {'name': 'Sinh Học', 'icon': Icons.eco, 'color': const Color(0xFFfa709a)},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.isMobile(context) ? 20 : 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Môn Học',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveUtils.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return _buildSubjectCard(subject, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject, int index) {
    return Container(
      decoration: BoxDecoration(
        color: (subject['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (subject['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to subject page
            print('Tapped on ${subject['name']}');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  subject['icon'] as IconData,
                  size: 40,
                  color: subject['color'] as Color,
                ),
                const SizedBox(height: 12),
                Text(
                  subject['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openBookReader(FlipBookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlipBookReaderPage(
          bookId: book.id,
          book: book,
        ),
      ),
    );
  }

  void _previousSlide() {
    if (_selectedBookIndex > 0) {
      setState(() {
        _selectedBookIndex--;
      });
      _bookInfoController.reset();
      _bookInfoController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _nextSlide() {
    if (_selectedBookIndex < _featuredBooks.length - 1) {
      setState(() {
        _selectedBookIndex++;
      });
      _bookInfoController.reset();
      _bookInfoController.forward();
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _bookInfoController.dispose();
    super.dispose();
  }
}














