import 'package:flutter/material.dart';
import 'ai_teaching_assistant.dart';

class AIOverlayWidget extends StatelessWidget {
  final bool showAI;
  final bool isMinimized;
  final VoidCallback onToggle;
  final String? currentPageContent;
  final Animation<Offset> slideAnimation;

  const AIOverlayWidget({
    super.key,
    required this.showAI,
    required this.isMinimized,
    required this.onToggle,
    required this.currentPageContent,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (!showAI) return const SizedBox.shrink();

    return Positioned(
      bottom: 20,
      left: 20,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          width: isMinimized ? 60 : 300,
          height: isMinimized ? 60 : 400,
          child: Stack(
            children: [
              // Background để block touch
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
              // AI Assistant
              AITeachingAssistant(
                width: 300,
                height: 400,
                isMinimized: isMinimized,
                onToggle: onToggle,
                currentPageContent: currentPageContent,
                onReadPage: (content) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}