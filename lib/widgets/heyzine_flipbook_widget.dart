import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Conditional imports for different platforms
import 'heyzine_flipbook_web.dart' if (dart.library.io) 'heyzine_flipbook_mobile.dart';

class HeyzineFlipbookWidget extends StatefulWidget {
  final String heyzineUrl;
  final double? width;
  final double? height;
  final Function(int)? onPageChanged;

  const HeyzineFlipbookWidget({
    super.key,
    required this.heyzineUrl,
    this.width,
    this.height,
    this.onPageChanged,
  });

  @override
  State<HeyzineFlipbookWidget> createState() => _HeyzineFlipbookWidgetState();
}

class _HeyzineFlipbookWidgetState extends State<HeyzineFlipbookWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 600,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: kIsWeb 
          ? HeyzineFlipbookPlatform(
              heyzineUrl: widget.heyzineUrl,
              onPageChanged: widget.onPageChanged,
            )
          : HeyzineFlipbookPlatform(
              heyzineUrl: widget.heyzineUrl,
              onPageChanged: widget.onPageChanged,
            ),
      ),
    );
  }
}




