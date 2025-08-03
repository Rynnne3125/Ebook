import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class TurnJSFlipbookWidget extends StatefulWidget {
  final List<Map<String, dynamic>> pages;
  final Function(int)? onPageChanged;
  final Function()? onReady;
  final int? initialPage;

  const TurnJSFlipbookWidget({
    super.key,
    required this.pages,
    this.onPageChanged,
    this.onReady,
    this.initialPage,
  });

  @override
  State<TurnJSFlipbookWidget> createState() => _TurnJSFlipbookWidgetState();
}

class _TurnJSFlipbookWidgetState extends State<TurnJSFlipbookWidget> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _isReady = false;
  int _currentPage = 1;
  String? _viewType;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    if (kIsWeb) {
      _initializeWebVersion();
    } else {
      _initializeMobileVersion();
    }
  }

  void _initializeWebVersion() {
    // For Flutter Web - use iframe
    _viewType = 'turnjs-flipbook-${DateTime.now().millisecondsSinceEpoch}';
    
    // Register iframe view
    ui.platformViewRegistry.registerViewFactory(
      _viewType!,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '/turnjs/turnjs.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

        // Listen for messages from iframe
        html.window.addEventListener('message', (event) {
          final messageEvent = event as html.MessageEvent;
          if (messageEvent.data is Map) {
            final data = messageEvent.data as Map<String, dynamic>;
            if (data['type'] == 'turnjs_event') {
              _handleTurnJSEvent(data['event'], data['data']);
            }
          }
        });

        // Initialize flipbook when iframe loads
        iframe.onLoad.listen((_) {
          _initializeFlipbook(iframe);
        });

        return iframe;
      },
    );
  }

  void _initializeMobileVersion() {
    // For mobile platforms - use WebView
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _initializeFlipbook(null);
          },
        ),
      )
      ..addJavaScriptChannel(
        'turnjs_event',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          _handleTurnJSEvent(data['event'], data['data']);
        },
      )
      ..loadFlutterAsset('assets/turnjs/turnjs.html');
  }

  void _initializeFlipbook(html.IFrameElement? iframe) async {
    // Wait a bit for the page to fully load
    await Future.delayed(const Duration(milliseconds: 500));

    final pagesJson = jsonEncode(widget.pages);

    if (kIsWeb && iframe != null) {
      // Send data to iframe
      iframe.contentWindow?.postMessage({
        'type': 'initialize_flipbook',
        'pages': widget.pages,
      }, '*');
    } else {
      // Send data to WebView
      await _webViewController.runJavaScript('''
        if (window.flutterBridge && window.flutterBridge.initializeFlipbook) {
          window.flutterBridge.initializeFlipbook($pagesJson);
        }
      ''');
    }

    if (widget.initialPage != null && widget.initialPage! > 1) {
      await Future.delayed(const Duration(milliseconds: 1000));
      goToPage(widget.initialPage!);
    }
  }

  void _handleTurnJSEvent(String event, Map<String, dynamic>? data) {
    print('📨 TurnJS Event: $event, Data: $data');

    switch (event) {
      case 'dom_ready':
        setState(() {
          _isLoading = false;
        });
        break;

      case 'flipbook_ready':
        setState(() {
          _isReady = true;
        });
        widget.onReady?.call();
        break;

      case 'page_turned':
        if (data != null && data['page'] != null) {
          final newPage = data['page'] as int;
          if (newPage != _currentPage) {
            setState(() {
              _currentPage = newPage;
            });
            widget.onPageChanged?.call(newPage);
          }
        }
        break;

      case 'page_turning':
        // Optional: Handle page turning event
        break;

      case 'page_image_loaded':
        // Optional: Handle individual page load
        break;

      case 'page_image_error':
        // Optional: Handle page load error
        if (data != null && data['page'] != null) {
          print('❌ Page ${data['page']} failed to load');
        }
        break;
    }
  }

  // Public methods for external control
  Future<void> goToPage(int pageNumber) async {
    if (!_isReady) return;

    if (kIsWeb) {
      // For web version - post message to iframe
      final iframe = html.document.querySelector('iframe[src="/turnjs/turnjs.html"]') as html.IFrameElement?;
      iframe?.contentWindow?.postMessage({
        'type': 'go_to_page',
        'page': pageNumber,
      }, '*');
    } else {
      // For mobile version - call JavaScript
      await _webViewController.runJavaScript('''
        if (window.flutterBridge && window.flutterBridge.goToPage) {
          window.flutterBridge.goToPage($pageNumber);
        }
      ''');
    }
  }

  Future<void> nextPage() async {
    if (_currentPage < widget.pages.length) {
      await goToPage(_currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 1) {
      await goToPage(_currentPage - 1);
    }
  }

  int get currentPage => _currentPage;
  bool get isReady => _isReady;
  int get totalPages => widget.pages.length;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebVersion();
    } else {
      return _buildMobileVersion();
    }
  }

  Widget _buildWebVersion() {
    return Stack(
      children: [
        if (_viewType != null)
          HtmlElementView(viewType: _viewType!),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải flipbook...'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobileVersion() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải flipbook...'),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Helper class for page data
class FlipbookPage {
  final int pageNumber;
  final String imageUrl;
  final int? width;
  final int? height;
  final String? cloudinaryId;

  FlipbookPage({
    required this.pageNumber,
    required this.imageUrl,
    this.width,
    this.height,
    this.cloudinaryId,
  });

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'imageUrl': imageUrl,
      'width': width,
      'height': height,
      'cloudinaryId': cloudinaryId,
    };
  }

  factory FlipbookPage.fromJson(Map<String, dynamic> json) {
    return FlipbookPage(
      pageNumber: json['pageNumber'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      width: json['width'],
      height: json['height'],
      cloudinaryId: json['cloudinaryId'],
    );
  }
}
