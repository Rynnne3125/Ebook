import 'package:flutter/material.dart';

class FlipBookPage {
  final String title;
  final String content;
  final bool isCover;
  final int pageNumber;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  FlipBookPage({
    required this.title,
    required this.content,
    required this.isCover,
    required this.pageNumber,
    this.imageUrl,
    this.metadata,
  });
}

