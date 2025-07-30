import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

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
  late String viewId;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      viewId = 'heyzine-iframe-${DateTime.now().millisecondsSinceEpoch}';
      _registerWebView();
    }
  }

  void _registerWebView() {
    ui.platformViewRegistry.registerViewFactory(
      viewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = widget.heyzineUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allowFullscreen = true
          ..setAttribute('allow', 'clipboard-write')
          ..setAttribute('scrolling', 'no');
        
        return iframe;
      },
    );
  }

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
          ? HtmlElementView(viewType: viewId)
          : _buildMobileWebView(),
      ),
    );
  }

  Widget _buildMobileWebView() {
    // Import webview_flutter only for mobile
    return Container(
      child: const Center(
        child: Text(
          'Mobile WebView\n(Cần import webview_flutter)',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}


