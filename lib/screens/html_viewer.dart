import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mgw_tutorial/constants/color.dart'; // Assuming this exists
import 'package:mgw_tutorial/l10n/app_localizations.dart'; // Assuming this exists

/// A widget that displays HTML content from a URL or a local file path.
///
/// Supports loading content from:
/// 1. Remote HTTP/HTTPS URLs (potentially relative to a base URL).
/// 2. Local files specified with a `file://` URI.
class HtmlViewer extends StatefulWidget {
  /// The URL or file path to load.
  ///
  /// If the URL starts with `file://`, it's treated as a local file path.
  /// Otherwise, it's treated as a remote URL. Relative URLs are prefixed
  /// with the `baseUrl`.
  final String url;

  /// The title to display in the app bar.
  final String title;

  const HtmlViewer({super.key, required this.url, required this.title});

  @override
  State<HtmlViewer> createState() => _HtmlViewerState();
}

class _HtmlViewerState extends State<HtmlViewer> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  AppLocalizations? _l10n; // Still keeping l10n as it's used elsewhere

  // Base URL for remote content if the provided URL is relative.
  // Consider making this configurable if needed.
  static const String baseUrl = "https://lessonservice.amtprinting19.com/api/lessons";

  // Subscription to listen for connectivity changes (optional, but can be useful)
  // StreamSubscription<ConnectivityResult>? _connectivitySubscription;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    // Start initialization here as context and l10n are available
    _initHtmlViewer();
  }

  // @override
  // void dispose() {
  //   // Cancel the connectivity subscription if it was created
  //   // _connectivitySubscription?.cancel();
  //   super.dispose();
  // }

  /// Initializes the HTML viewer by determining the content source
  /// and attempting to load it.
  Future<void> _initHtmlViewer() async {
    // Ensure the widget is still in the tree before updating state
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    print('Initializing HtmlViewer with URL: ${widget.url}');

    try {
      // Determine if it's a local file path based ONLY on the file:// prefix
      final isLocalUrl = widget.url.startsWith('file://');
      print('Is local URL (based on file:// prefix): $isLocalUrl (URL: ${widget.url})');

      if (isLocalUrl) {
        // Extract the actual path from the file URI
        final localPath = Uri.parse(widget.url).toFilePath();
        print('Attempting to load local file from path: $localPath');
        await _loadLocalHtml(localPath);
      } else {
        // Assume it's a remote URL
        // Check connectivity before attempting a network request
        final connection = await Connectivity().checkConnectivity();
        final hasConnection = connection != ConnectivityResult.none && connection != ConnectivityResult.vpn; // Consider VPN as online
        print('Connectivity: ${hasConnection ? 'Online' : 'Offline'}');

        if (!hasConnection) {
           // No connection, set error and finish loading state
          setState(() {
            _isLoading = false;
            // Use hardcoded string for no internet
            _errorMessage = 'No internet connection available.';
            _controller = null; // Ensure no partial webview is shown without connection
          });
           print('Load aborted due to no internet connection.');
          return; // Stop initialization
        }

        // Construct the full URL
        final fullUrl = widget.url.startsWith('http') ? widget.url : '$baseUrl${widget.url.startsWith('/') ? '' : '/'}${widget.url}';
        print('Attempting to load online URL: $fullUrl');

        // Validate the URL format
        final uri = Uri.tryParse(fullUrl);
        // Check if it's absolute and has a valid scheme (http or https)
        if (uri == null || !uri.isAbsolute || (uri.scheme != 'http' && uri.scheme != 'https')) {
          setState(() {
            _isLoading = false;
             // Use hardcoded string for invalid URL
            _errorMessage = 'Invalid URL format: $fullUrl';
            _controller = null; // Ensure no partial webview
          });
          print('Invalid URL format detected: $fullUrl');
          return; // Stop initialization
        }

        // Load online content with a timeout
        await _loadOnlineHtml(fullUrl).timeout( // Use fullUrl here
          const Duration(seconds: 15), // Increased timeout slightly
          onTimeout: () {
            // This timeout occurs if loadRequest takes too long *to initiate* or the future returned by it doesn't complete.
            // The delegate's onWebResourceError handles errors *during* the actual page loading.
             print('Timeout during online load initialization for URL: $fullUrl');
             if (mounted) { // Check mounted again inside timeout callback
                setState(() {
                  _isLoading = false;
                  // Use hardcoded string for timeout
                  _errorMessage = 'Loading timed out for $fullUrl.';
                  _controller = null; // Ensure no partial webview
                });
             }
          },
        );
      }
    } catch (e, stackTrace) {
      // Catch errors during initial checks (file not found check, connectivity check, etc.)
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Use available l10n key with fallback for general load error
          _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load content'}: $e';
          _controller = null; // Ensure no partial webview
          print('Error during _initHtmlViewer: $e\n$stackTrace');
        });
      }
    }
  }

  /// Configures and loads an online HTML page using WebViewController.
  Future<void> _loadOnlineHtml(String url) async {
     if (!mounted) return;

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        // Set background color to match app theme while loading
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
               // Optional: Update UI with loading progress if needed
               // print('WebView loading progress: $progress% for $url');
            },
            onPageStarted: (_) {
              print('WebView: Page started loading: $url');
              if (mounted) {
                 // setState(() => _isLoading = true); // Redundant if _initHtmlViewer manages it
              }
            },
            onPageFinished: (_) {
              print('WebView: Page finished loading: $url');
               if (mounted) {
                 // Set loading to false when the page reports it's finished
                 setState(() => _isLoading = false);
               }
            },
            onWebResourceError: (error) {
              print('WebView resource error for $url: ${error.errorCode}, ${error.description}');
              // An error occurred *within* the webview. Display the error but keep the controller.
              if (mounted) {
                 setState(() {
                   _isLoading = false; // Loading is definitely finished (with an error)
                   // Use available l10n key with fallback for general load error + description
                   _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load'}: ${error.description}';
                 });
              }
            },
             onNavigationRequest: (request) {
                // print('Allowing navigation to: ${request.url}');
                return NavigationDecision.navigate; // Allow navigation by default
             },
          ),
        );

      // Load the requested URL
      await controller.loadRequest(Uri.parse(url));

      // Update state to show the webview. Keep _isLoading true until onPageFinished.
      if (mounted) {
         setState(() {
           _controller = controller;
           // _isLoading remains true, will be set to false by onPageFinished or onWebResourceError
         });
      }

    } catch (e, stackTrace) {
      // Catch errors during controller creation or initial loadRequest call
      if (mounted) {
        setState(() {
          _isLoading = false; // Loading process failed
           // Use available l10n key with fallback for general load error
          _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load content'}: $e';
          _controller = null; // Ensure no controller is used if load setup failed
          print('Error loading online HTML: $e\n$stackTrace');
        });
      }
    }
  }

  /// Configures and loads a local HTML file using WebViewController.
  Future<void> _loadLocalHtml(String path) async {
     if (!mounted) return;

    try {
      print('Loading local HTML from path: $path');
      final file = File(path);
      // Check if the local file exists before attempting to load
      if (!await file.exists()) {
        print('Local file not found at path: $path during load attempt.');
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Use available l10n key with fallback, passing the path in the error
            _errorMessage = _l10n?.couldNotOpenFileError(path) ?? 'File not found: $path';
            _controller = null; // No controller to show if file doesn't exist
          });
        }
        return; // Stop loading process
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
               // print('WebView loading progress: $progress% for $path');
            },
            onPageStarted: (_) {
              print('WebView: Local page started loading: $path');
               if (mounted) {
                // setState(() => _isLoading = true); // Redundant if managed by _initHtmlViewer
               }
            },
            onPageFinished: (_) {
              print('WebView: Local page finished loading: $path');
               if (mounted) {
                 setState(() => _isLoading = false);
               }
            },
            onWebResourceError: (error) {
              print('WebView resource error for local file $path: ${error.errorCode}, ${error.description}');
               if (mounted) {
                 setState(() {
                   _isLoading = false;
                    // Use available l10n key with fallback, including path and description
                   _errorMessage = _l10n?.couldNotOpenFileError('$path: ${error.description}') ?? 'Failed to open file: $path - ${error.description}';
                   // Keep controller if page started loading before error? Or nullify? Let's keep it for now per previous refactor.
                   // _controller = null; // Only nullify if the error is fatal
                 });
               }
            },
             onNavigationRequest: (request) {
                // Allow local file navigation or prevent? Usually allow for local files.
                print('Allowing local navigation to: ${request.url}');
                return NavigationDecision.navigate;
             },
          ),
        );

      // pass the direct file path to loadFile, not the file:// URI string
      await controller.loadFile(path);

      // Update state to show the webview. Keep _isLoading true until onPageFinished.
       if (mounted) {
         setState(() {
           _controller = controller;
           // _isLoading remains true, will be set to false by onPageFinished or onWebResourceError
         });
       }

    } catch (e, stackTrace) {
       // Catch errors during controller creation or initial loadFile call
       if (mounted) {
         setState(() {
           _isLoading = false; // Loading process failed
           // Use available l10n key with fallback, including path and error
           _errorMessage = _l10n?.couldNotOpenFileError('$path: $e') ?? 'Failed to open file: $path - $e';
           _controller = null; // Ensure no controller if load setup failed
           print('Error loading local HTML from path: $path - $e\n$stackTrace');
         });
       }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Guaranteed available after didChangeDependencies
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight; // Use AppColors for consistency
    final dynamicErrorColor = AppColors.error; // Assuming AppColors.error is theme-agnostic

    return Scaffold(
      // Use theme colors for AppBar for consistency
      appBar: AppBar(
        title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        // The default AppBar background comes from Theme.of(context).appBarTheme or ColorScheme.primary
        // If you need specific colors, use:
        // backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight, // Assuming these exist
      ),
      body: Stack(
        children: [
          // 1. WebView Widget (Base Layer)
          // Only show the WebViewWidget if the controller is initialized AND there's no fatal error preventing its display.
          // If an error occurred *during* loading (onWebResourceError), we keep the controller
          // and display the error message *over* the potentially partially loaded page.
          // If an error occurred *before* the controller was even ready (_initHtmlViewer catch),
          // then _controller is null, and the WebViewWidget won't be built.
          if (_controller != null)
            WebViewWidget(controller: _controller!),

          // 2. Error Message Overlay (Middle Layer)
          // Show the error message centered if there is one.
          if (_errorMessage != null)
            Center(
              child: Container( // Wrap in Container for padding/margins if needed
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  children: [
                    Icon(Icons.error_outline, color: dynamicErrorColor, size: 50),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: dynamicOnSurfaceColor, fontSize: 16),
                    ),
                     const SizedBox(height: 24),
                     ElevatedButton(
                       onPressed: _initHtmlViewer, // Provide a retry mechanism
                       child: Text(l10n.refresh), // Use existing 'refresh' key for retry
                     ),
                  ],
                ),
              ),
            ),

          // 3. Loading Indicator Overlay (Top Layer)
          // Show the loading indicator while _isLoading is true.
          // This covers the content/error message below it.
          if (_isLoading)
            Container(
              // Use Theme's background color with some opacity for the overlay
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
              child: Center(
                child: CircularProgressIndicator(color: dynamicPrimaryColor),
              ),
            ),
        ],
      ),
    );
  }
}