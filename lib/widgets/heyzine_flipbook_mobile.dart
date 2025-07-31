import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar if needed
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // Inject CSS để ẩn UI không cần thiết
            controller.runJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = `
                .heyzine-toolbar, .heyzine-logo, .heyzine-branding,
                [class*="heyzine"], [id*="heyzine"], .logo, .branding {
                  display: none !important;
                  visibility: hidden !important;
                }
              `;
              document.head.appendChild(style);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.heyzineUrl));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}



