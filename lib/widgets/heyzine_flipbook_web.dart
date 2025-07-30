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
    _registerIframe();
  }

  void _registerIframe() {
    // Register iframe element
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.heyzineUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..setAttribute('allow', 'clipboard-write');
        
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

