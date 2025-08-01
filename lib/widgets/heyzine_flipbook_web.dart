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

// Global controller for Heyzine flipbook
class HeyzineFlipbookController {
  static HeyzineFlipbookController? _instance;
  html.IFrameElement? _iframe;
  String? _baseUrl;
  Function(String)? _onIframeRecreate;
  Function(int)? _onPageChanged;

  static HeyzineFlipbookController get instance {
    _instance ??= HeyzineFlipbookController._();
    return _instance!;
  }

  HeyzineFlipbookController._() {
    _setupMessageListener();
  }

  void _setupMessageListener() {
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      print('📨 Received message from iframe: ${messageEvent.data}');

      // Try to parse Heyzine messages
      try {
        if (messageEvent.data is Map) {
          final data = messageEvent.data as Map;
          if (data.containsKey('page') || data.containsKey('currentPage')) {
            print('📖 Heyzine page info: $data');
            _handlePageChange(data);
          }
        } else if (messageEvent.data is String) {
          final dataStr = messageEvent.data as String;
          if (dataStr.contains('page') || dataStr.contains('flip')) {
            print('📖 Heyzine string message: $dataStr');
            _parsePageFromString(dataStr);
          }
        }
      } catch (e) {
        print('⚠️ Error parsing message: $e');
      }
    });

    // Also listen for iframe load events to inject page detection script
    html.window.addEventListener('load', (event) {
      _injectPageDetectionScript();
    });

    print('👂 Message listener setup for Heyzine communication');
  }

  void _handlePageChange(Map data) {
    int? pageNumber;
    if (data.containsKey('page')) {
      pageNumber = data['page'] as int?;
    } else if (data.containsKey('currentPage')) {
      pageNumber = data['currentPage'] as int?;
    }

    if (pageNumber != null && _onPageChanged != null) {
      print('🔄 Heyzine page changed to: $pageNumber');
      _onPageChanged!(pageNumber);
    }
  }

  void _parsePageFromString(String message) {
    // Try to extract page number from string messages
    final pageRegex = RegExp(r'page[:\s]*(\d+)', caseSensitive: false);
    final match = pageRegex.firstMatch(message);
    if (match != null) {
      final pageNumber = int.tryParse(match.group(1) ?? '');
      if (pageNumber != null && _onPageChanged != null) {
        print('🔄 Heyzine page changed to: $pageNumber (from string)');
        _onPageChanged!(pageNumber);
      }
    }
  }

  void _injectPageDetectionScript() {
    if (_iframe != null) {
      Timer(const Duration(seconds: 3), () {
        try {
          // Try to inject page detection and navigation hiding script
          _iframe!.contentWindow?.postMessage({
            'type': 'inject-script',
            'script': '''
              // Hide navigation buttons with CSS
              function hideNavigationButtons() {
                const style = document.createElement('style');
                style.textContent = `
                  /* Hide common navigation button selectors */
                  .navigation, .nav-buttons, .page-nav,
                  .next-page, .prev-page, .page-controls,
                  .flipbook-nav, .flipbook-controls,
                  [class*="nav"], [class*="button"], [class*="control"],
                  button[title*="next"], button[title*="prev"],
                  button[title*="Next"], button[title*="Previous"],
                  .arrow-left, .arrow-right, .page-arrow,
                  .btn-next, .btn-prev, .btn-forward, .btn-back {
                    display: none !important;
                    visibility: hidden !important;
                    opacity: 0 !important;
                    pointer-events: none !important;
                  }

                  /* Hide toolbar and controls */
                  .toolbar, .controls, .ui-controls,
                  .flipbook-toolbar, .viewer-toolbar {
                    display: none !important;
                  }
                `;
                document.head.appendChild(style);
                console.log('🚫 Navigation buttons hidden');
              }

              // Monitor for page changes in Heyzine
              let lastPage = 1;

              function detectPageChange() {
                // Try different methods to get current page
                let currentPage = null;

                if (window.flipbook && window.flipbook.getCurrentPage) {
                  currentPage = window.flipbook.getCurrentPage();
                } else if (window.viewer && window.viewer.currentPage) {
                  currentPage = window.viewer.currentPage;
                } else if (window.book && window.book.currentPage) {
                  currentPage = window.book.currentPage;
                }

                if (currentPage && currentPage !== lastPage) {
                  lastPage = currentPage;
                  window.parent.postMessage({
                    type: 'heyzine-page-change',
                    page: currentPage
                  }, '*');
                }
              }

              // Apply hiding when DOM is ready
              if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', hideNavigationButtons);
              } else {
                hideNavigationButtons();
              }

              // Also apply after a delay to catch dynamically loaded elements
              setTimeout(hideNavigationButtons, 2000);
              setTimeout(hideNavigationButtons, 5000);

              // Monitor clicks and keyboard events
              document.addEventListener('click', () => {
                setTimeout(detectPageChange, 100);
              });

              document.addEventListener('keydown', (e) => {
                if (e.key === 'ArrowLeft' || e.key === 'ArrowRight' || e.key === 'Space') {
                  setTimeout(detectPageChange, 100);
                }
              });

              // Periodic check
              setInterval(detectPageChange, 1000);
            '''
          }, '*');
          print('📜 Page detection and navigation hiding script injected');
        } catch (e) {
          print('❌ Error injecting scripts: $e');
        }
      });
    }
  }

  void setIframe(html.IFrameElement iframe, {String? baseUrl, Function(String)? onRecreate, Function(int)? onPageChanged}) {
    _iframe = iframe;
    _baseUrl = baseUrl;
    _onIframeRecreate = onRecreate;
    _onPageChanged = onPageChanged;
    print('🔗 Heyzine iframe registered for page control');
  }

  void recreateIframeWithPage(int pageNumber) {
    if (_baseUrl != null && _onIframeRecreate != null) {
      final pageUrl = '$_baseUrl?page=$pageNumber';
      print('🔄 Recreating iframe with page URL: $pageUrl');
      _onIframeRecreate!(pageUrl);
    }
  }

  void goToPage(int pageNumber) {
    if (_iframe != null) {
      print('📖 Testing Heyzine page control for page $pageNumber');

      try {
        // Method 1: URL reload with page parameter
        final currentSrc = _iframe!.src;
        if (currentSrc != null) {
          // Try different URL formats
          final baseUrl = currentSrc.split('?')[0].split('#')[0];

          // Test multiple URL formats
          final urlFormats = [
            '$baseUrl?page=$pageNumber',
            '$baseUrl#page=$pageNumber',
            '$baseUrl#p$pageNumber',
            '$baseUrl?p=$pageNumber',
            '$baseUrl#$pageNumber',
          ];

          for (final url in urlFormats) {
            print('🔗 Testing URL format: $url');

            // Create a new iframe with the page URL
            Timer(Duration(milliseconds: 100 * urlFormats.indexOf(url)), () {
              if (urlFormats.indexOf(url) == 0) {
                // Only reload for the first format to avoid multiple reloads
                _iframe!.src = url;
                print('✅ Iframe reloaded with page URL');
              }
            });
          }
        }

        // Method 2: Focus iframe and simulate keyboard
        try {
          // Focus the iframe first
          _iframe!.focus();

          // Send keyboard events
          final keyEvents = ['ArrowRight', 'PageDown', 'Space'];
          for (final key in keyEvents) {
            _iframe!.contentWindow?.postMessage({
              'type': 'keypress',
              'key': key,
              'target': 'flipbook'
            }, '*');
          }
          print('⌨️ Keyboard events sent to iframe');
        } catch (e) {
          print('⚠️ Keyboard simulation failed: $e');
        }

      } catch (e) {
        print('❌ Error controlling Heyzine page: $e');
      }
    } else {
      print('❌ Heyzine iframe not available for page control');
    }
  }
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

        // Register iframe with controller for page control
        HeyzineFlipbookController.instance.setIframe(
          iframe,
          baseUrl: widget.heyzineUrl,
          onPageChanged: widget.onPageChanged,
        );

        // Add load event listener to monitor iframe
        iframe.onLoad.listen((event) {
          print('🔄 Heyzine iframe loaded');

          // Try to inspect iframe after load
          Timer(const Duration(seconds: 2), () {
            try {
              print('🔍 Attempting to communicate with Heyzine iframe...');

              // Send debug message to iframe
              iframe.contentWindow?.postMessage({
                'type': 'debug-request',
                'action': 'get-info'
              }, '*');

              // Try different page control messages
              iframe.contentWindow?.postMessage({
                'type': 'page-control',
                'page': 1
              }, '*');

              print('📨 Debug messages sent to iframe');
            } catch (e) {
              print('❌ Error communicating with iframe: $e');
            }
          });
        });
        
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






