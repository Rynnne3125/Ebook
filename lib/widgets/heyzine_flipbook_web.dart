import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class HeyzineFlipbookPlatform extends StatefulWidget {
  final String heyzineUrl;
  final Function(int)? onPageChanged;

  const HeyzineFlipbookPlatform({
    super.key,
    required this.heyzineUrl,
    this.onPageChanged,
  });

  @override
  State<HeyzineFlipbookPlatform> createState() => _HeyzineFlipbookPlatformState();
}

class _HeyzineFlipbookPlatformState extends State<HeyzineFlipbookPlatform> {
  late String viewId;

  @override
  void initState() {
    super.initState();
    viewId = 'heyzine-iframe-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
  }

  void _registerWebView() {
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        // Thêm parameters để ẩn UI Heyzine
        String modifiedUrl = widget.heyzineUrl;
        if (!modifiedUrl.contains('?')) {
          modifiedUrl += '?hide_ui=true&hide_logo=true&hide_toolbar=true';
        } else {
          modifiedUrl += '&hide_ui=true&hide_logo=true&hide_toolbar=true';
        }
        
        final iframe = html.IFrameElement()
          ..src = modifiedUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'auto' // Đảm bảo pointer events hoạt động
          ..style.zIndex = '1' // Z-index thấp hơn AI Assistant
          ..allowFullscreen = true
          ..setAttribute('allow', 'clipboard-write')
          ..setAttribute('scrolling', 'no');
        
        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(
      viewType: viewId,
    );
  }
}






