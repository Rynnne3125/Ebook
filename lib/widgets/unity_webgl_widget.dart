import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class UnityWebGLWidget extends StatefulWidget {
  final double width;
  final double height;
  final bool isMinimized;
  final VoidCallback? onToggle;
  final String? unityBuildPath;

  const UnityWebGLWidget({
    super.key,
    this.width = 300,
    this.height = 200,
    this.isMinimized = false,
    this.onToggle,
    this.unityBuildPath = 'assets/Build/WebGL/index.html',
  });

  @override
  State<UnityWebGLWidget> createState() => _UnityWebGLWidgetState();
}

class _UnityWebGLWidgetState extends State<UnityWebGLWidget>
    with SingleTickerProviderStateMixin {
  late String viewId;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (kIsWeb) {
      viewId = 'unity-webgl-${DateTime.now().millisecondsSinceEpoch}';
      _registerUnityWebGL();
    }
    
    _animationController.forward();
  }

  void _registerUnityWebGL() {
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.unityBuildPath!
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.borderRadius = '12px'
          ..allowFullscreen = false
          ..setAttribute('allow', 'microphone; camera')
          ..setAttribute('scrolling', 'no');
        
        return iframe;
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.isMinimized ? 60 : widget.width,
              height: widget.isMinimized ? 60 : widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF667eea).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Unity WebGL Content
                    if (!widget.isMinimized)
                      Positioned.fill(
                        child: kIsWeb 
                          ? HtmlElementView(viewType: viewId)
                          : _buildFallbackView(),
                      ),
                    
                    // Minimized state
                    if (widget.isMinimized)
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    
                    // Control buttons
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.isMinimized)
                            _buildControlButton(
                              icon: Icons.minimize,
                              onTap: widget.onToggle,
                            ),
                          if (widget.isMinimized)
                            _buildControlButton(
                              icon: Icons.open_in_full,
                              onTap: widget.onToggle,
                            ),
                        ],
                      ),
                    ),
                    
                    // AI Assistant label
                    if (!widget.isMinimized)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'AI Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }

  Widget _buildFallbackView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF667eea),
            const Color(0xFF764ba2),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'AI Assistant',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Unity WebGL',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}