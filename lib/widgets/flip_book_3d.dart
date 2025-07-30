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
  late Animation<double> _flipAnimation;
  
  int currentPage = 0;
  bool isFlipping = false;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    ));
  }

  void _flipToNext() {
    if (isFlipping || currentPage >= widget.pages.length - 1) return;
    
    setState(() {
      isFlipping = true;
    });
    
    _flipController.forward().then((_) {
      setState(() {
        currentPage++;
        isFlipping = false;
      });
      _flipController.reset();
      widget.onPageChanged?.call(currentPage);
    });
  }

  void _flipToPrevious() {
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
      widget.onPageChanged?.call(currentPage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () => _flipToNext(),
        onSecondaryTap: () => _flipToPrevious(),
        child: Container(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              _buildBookShadow(),
              _buildLeftPage(),
              _buildRightPage(),
              if (isFlipping) _buildFlippingPage(),
              if (isHovered && !isFlipping) _buildNavigationHints(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookShadow() {
    return Positioned(
      bottom: 0,
      left: widget.width * 0.1,
      right: widget.width * 0.1,
      child: Container(
        height: 20,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPage() {
    final leftPageIndex = currentPage > 0 ? currentPage - 1 : 0;
    
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        width: widget.width / 2,
        height: widget.height,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            bottomLeft: Radius.circular(12),
          ),
          child: Stack(
            children: [
              widget.pages[leftPageIndex],
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
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
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(-2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          child: Stack(
            children: [
              widget.pages[currentPage],
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.15),
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
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final progress = _flipAnimation.value;
        final angle = progress * math.pi;
        
        return Positioned(
          right: 0,
          top: 0,
          child: Transform(
            alignment: Alignment.centerLeft,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(-angle),
            child: Container(
              width: widget.width / 2,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(-5 * progress, 0),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    if (angle < math.pi / 2)
                      widget.pages[currentPage]
                    else
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(-1.0, 1.0),
                        child: widget.pages[
                          currentPage < widget.pages.length - 1 
                            ? currentPage + 1 
                            : currentPage
                        ],
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.3 * progress),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationHints() {
    return Row(
      children: [
        if (currentPage > 0)
          Expanded(
            child: GestureDetector(
              onTap: _flipToPrevious,
              child: Container(
                color: Colors.transparent,
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
        
        if (currentPage < widget.pages.length - 1)
          Expanded(
            child: GestureDetector(
              onTap: _flipToNext,
              child: Container(
                color: Colors.transparent,
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox()),
      ],
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }
}