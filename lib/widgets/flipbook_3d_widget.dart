import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipBook3D extends StatefulWidget {
  final List<Widget> pages;
  final double width;
  final double height;
  final Function(int)? onPageChanged;
  
  const FlipBook3D({
    super.key,
    required this.pages,
    this.width = 600,
    this.height = 800,
    this.onPageChanged,
  });

  @override
  State<FlipBook3D> createState() => _FlipBook3DState();
}

class _FlipBook3DState extends State<FlipBook3D>
    with TickerProviderStateMixin {
  
  late AnimationController _flipController;
  late AnimationController _shadowController;
  late AnimationController _curveController;
  
  late Animation<double> _flipAnimation;
  late Animation<double> _shadowAnimation;
  late Animation<double> _curveAnimation;
  
  int currentPage = 0;
  bool isFlipping = false;
  bool isFlippingForward = true;
  bool isHovered = false;
  
  Offset? _dragStart;
  double _dragProgress = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _shadowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _curveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shadowController,
      curve: Curves.easeInOut,
    ));
    
    _curveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _curveController,
      curve: Curves.elasticOut,
    ));
  }

  void _flipToNext() {
    if (isFlipping || currentPage >= widget.pages.length - 1) return;
    
    setState(() {
      isFlipping = true;
      isFlippingForward = true;
    });
    
    _shadowController.forward();
    _curveController.forward();
    _flipController.forward().then((_) {
      setState(() {
        currentPage++;
        isFlipping = false;
      });
      _flipController.reset();
      _shadowController.reverse();
      _curveController.reverse();
      widget.onPageChanged?.call(currentPage);
    });
  }

  void _flipToPrevious() {
    if (isFlipping || currentPage <= 0) return;
    
    setState(() {
      isFlipping = true;
      isFlippingForward = false;
    });
    
    _shadowController.forward();
    _curveController.forward();
    _flipController.forward().then((_) {
      setState(() {
        currentPage--;
        isFlipping = false;
      });
      _flipController.reset();
      _shadowController.reverse();
      _curveController.reverse();
      widget.onPageChanged?.call(currentPage);
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (isFlipping) return;
    
    setState(() {
      _dragStart = details.localPosition;
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _dragStart == null) return;
    
    final dx = details.localPosition.dx - _dragStart!.dx;
    final progress = (dx / (widget.width / 2)).clamp(-1.0, 1.0);
    
    setState(() {
      _dragProgress = progress.abs();
    });
    
    if (progress > 0 && currentPage > 0) {
      // Dragging right (previous page)
      isFlippingForward = false;
    } else if (progress < 0 && currentPage < widget.pages.length - 1) {
      // Dragging left (next page)
      isFlippingForward = true;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    if (_dragProgress > 0.3) {
      if (isFlippingForward) {
        _flipToNext();
      } else {
        _flipToPrevious();
      }
    }
    
    setState(() {
      _dragProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Container(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // Book shadow
              _buildBookShadow(),
              
              // Book spine
              _buildBookSpine(),
              
              // Left page (previous or current)
              _buildLeftPage(),
              
              // Right page (current or next)
              _buildRightPage(),
              
              // Flipping page
              if (isFlipping || _isDragging) _buildFlippingPage(),
              
              // Page curl effect
              if (isHovered && !isFlipping) _buildPageCurl(),
              
              // Navigation areas
              _buildNavigationAreas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookShadow() {
    return Positioned(
      left: 10,
      top: 15,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSpine() {
    return Positioned(
      left: widget.width / 2 - 4,
      top: 0,
      child: Container(
        width: 8,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.1),
              Colors.black.withOpacity(0.3),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPage() {
    final pageIndex = currentPage > 0 ? currentPage - 1 : 0;
    
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: widget.width / 2,
        height: widget.height,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
          child: Stack(
            children: [
              widget.pages[pageIndex],
              // Left page binding shadow
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPage() {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: widget.width / 2,
        height: widget.height,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          child: Stack(
            children: [
              widget.pages[currentPage],
              // Right page binding shadow
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlippingPage() {
    final progress = _isDragging ? _dragProgress : _flipAnimation.value;
    final angle = progress * math.pi;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_flipAnimation, _shadowAnimation]),
      builder: (context, child) {
        return Positioned(
          left: isFlippingForward ? widget.width / 2 : 0,
          top: 0,
          child: Transform(
            alignment: isFlippingForward 
                ? Alignment.centerLeft 
                : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(isFlippingForward ? -angle : angle),
            child: Container(
              width: widget.width / 2,
              height: widget.height,
              child: Stack(
                children: [
                  // Page content
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: angle >= math.pi / 2
                        ? _buildFlippedPageContent()
                        : _buildCurrentPageContent(),
                  ),
                  
                  // Flip shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: isFlippingForward 
                            ? Alignment.centerLeft 
                            : Alignment.centerRight,
                        end: isFlippingForward 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        colors: [
                          Colors.black.withOpacity(0.2 * _shadowAnimation.value),
                          Colors.transparent,
                        ],
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

  Widget _buildCurrentPageContent() {
    return widget.pages[currentPage];
  }

  Widget _buildFlippedPageContent() {
    final nextPageIndex = isFlippingForward 
        ? math.min(currentPage + 1, widget.pages.length - 1)
        : math.max(currentPage - 1, 0);
    
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0),
      child: widget.pages[nextPageIndex],
    );
  }

  Widget _buildPageCurl() {
    return Positioned(
      right: 0,
      top: 0,
      child: AnimatedBuilder(
        animation: _curveAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(50, 50),
            painter: PageCurlPainter(
              progress: isHovered ? 0.3 : 0.0,
              color: Colors.white.withOpacity(0.8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationAreas() {
    return Row(
      children: [
        // Previous area
        Expanded(
          child: GestureDetector(
            onTap: _flipToPrevious,
            child: Container(
              color: Colors.transparent,
              child: currentPage > 0 && isHovered
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
        
        // Next area
        Expanded(
          child: GestureDetector(
            onTap: _flipToNext,
            child: Container(
              color: Colors.transparent,
              child: currentPage < widget.pages.length - 1 && isHovered
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
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shadowController.dispose();
    _curveController.dispose();
    super.dispose();
  }
}

class PageCurlPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  PageCurlPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final curlSize = size.width * progress;
    
    path.moveTo(size.width - curlSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, curlSize);
    path.quadraticBezierTo(
      size.width - curlSize / 2,
      curlSize / 2,
      size.width - curlSize,
      0,
    );
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    canvas.drawPath(path, shadowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


