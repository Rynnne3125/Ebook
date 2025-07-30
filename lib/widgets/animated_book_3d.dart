import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedBook3D extends StatefulWidget {
  const AnimatedBook3D({super.key});

  @override
  State<AnimatedBook3D> createState() => _AnimatedBook3DState();
}

class _AnimatedBook3DState extends State<AnimatedBook3D>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _hoverController;
  late AnimationController _floatController;
  late Animation<double> _flipAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _floatAnimation;
  
  int currentPage = 0;
  bool isFlipping = false;
  bool isHovered = false;
  
  final List<BookPage> pages = [
    BookPage(
      title: "Phản Ứng Hóa Học",
      content: "Khám phá thế giới\nhóa học qua\nnhững thí nghiệm\nthú vị",
      backgroundColor: const Color(0xFF667eea),
      textColor: Colors.white,
      isCover: true,
    ),
    BookPage(
      title: "Chương 1: Giới Thiệu",
      content: "Phản ứng hóa học là gì?\n\n• Định nghĩa cơ bản\n• Các loại phản ứng\n• Ví dụ thực tế\n\nPhản ứng hóa học là quá trình biến đổi chất này thành chất khác có tính chất hoàn toàn mới.",
      backgroundColor: Colors.white,
      textColor: Colors.black87,
    ),
    BookPage(
      title: "Chương 2: Dấu Hiệu",
      content: "Nhận biết phản ứng:\n\n• Tỏa nhiệt, ánh sáng\n• Thay đổi màu sắc\n• Xuất hiện kết tủa\n• Tạo bọt khí\n• Thay đổi mùi vị\n\nVí dụ: Khi đốt nến, ta thấy ánh sáng, nhiệt và khói.",
      backgroundColor: Colors.white,
      textColor: Colors.black87,
    ),
    BookPage(
      title: "Chương 3: Thí Nghiệm",
      content: "Thí nghiệm đơn giản:\n\n1. Chuẩn bị dụng cụ\n2. Quan sát hiện tượng\n3. Ghi chép kết quả\n4. Rút ra kết luận\n\nLưu ý an toàn khi làm thí nghiệm!",
      backgroundColor: Colors.white,
      textColor: Colors.black87,
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _hoverController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _flipToNextPage() {
    if (isFlipping || currentPage >= pages.length - 1) return;
    
    setState(() {
      isFlipping = true;
    });

    _flipController.forward().then((_) {
      setState(() {
        currentPage++;
        isFlipping = false;
      });
      _flipController.reset();
    });
  }

  void _flipToPreviousPage() {
    if (isFlipping || currentPage <= 0) return;
    
    setState(() {
      isFlipping = true;
    });

    _flipController.forward().then((_) {
      setState(() {
        currentPage--;
        isFlipping = false;
      });
      _flipController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => isHovered = false);
        _hoverController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverAnimation, _floatAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(
              scale: _hoverAnimation.value,
              child: Container(
                width: 400,
                height: 550,
                child: Stack(
                  children: [
                    // Shadow
                    Positioned(
                      left: 15,
                      top: 15,
                      child: Container(
                        width: 400,
                        height: 550,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Book
                    AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        return _buildBook();
                      },
                    ),
                    // Navigation overlay
                    if (isHovered) _buildNavigationOverlay(),
                    // Page indicator
                    _buildPageIndicator(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBook() {
    return Container(
      width: 400,
      height: 550,
      child: Stack(
        children: [
          // Current page
          _buildPage(pages[currentPage], false),
          
          // Flipping page (if flipping)
          if (isFlipping)
            _buildFlippingPage(),
        ],
      ),
    );
  }

  Widget _buildFlippingPage() {
    final nextPageIndex = currentPage < pages.length - 1 ? currentPage + 1 : currentPage;
    final nextPage = pages[nextPageIndex];
    
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        
        if (angle >= math.pi / 2) {
          // Show back of flipping page (next page content)
          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(math.pi),
            child: _buildPage(nextPage, true),
          );
        } else {
          // Show front of flipping page (current page content)
          return Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-angle),
            child: _buildPage(pages[currentPage], true),
          );
        }
      },
    );
  }

  Widget _buildPage(BookPage page, bool isFlipping) {
    return Container(
      width: 400,
      height: 550,
      decoration: BoxDecoration(
        color: page.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        gradient: page.isCover ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              page.title,
              style: TextStyle(
                fontSize: page.isCover ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: page.textColor,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Text(
                page.content,
                style: TextStyle(
                  fontSize: page.isCover ? 20 : 16,
                  color: page.textColor,
                  height: 1.6,
                ),
              ),
            ),
            if (!page.isCover)
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${currentPage + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationOverlay() {
    return Positioned.fill(
      child: Row(
        children: [
          // Previous page area
          Expanded(
            child: GestureDetector(
              onTap: _flipToPreviousPage,
              child: Container(
                color: Colors.transparent,
                child: currentPage > 0
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
          // Next page area
          Expanded(
            child: GestureDetector(
              onTap: _flipToNextPage,
              child: Container(
                color: Colors.transparent,
                child: currentPage < pages.length - 1
                    ? const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 30,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pages.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == currentPage ? 12 : 8,
            height: index == currentPage ? 12 : 8,
            decoration: BoxDecoration(
              color: index == currentPage
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      ),
    );
  }
}

class BookPage {
  final String title;
  final String content;
  final Color backgroundColor;
  final Color textColor;
  final bool isCover;

  BookPage({
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.textColor,
    this.isCover = false,
  });
}

