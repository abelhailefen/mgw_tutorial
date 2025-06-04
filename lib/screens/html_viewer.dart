import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class HtmlViewer extends StatefulWidget {
  final String url;
  final String title;

  const HtmlViewer({super.key, required this.url, required this.title});

  @override
  State<HtmlViewer> createState() => _HtmlViewerState();
}

class _HtmlViewerState extends State<HtmlViewer> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasConnection = false;
  String? _errorMessage;
  AppLocalizations? _l10n;

  static const String baseUrl = "https://lessonservice.amtprinting19.com/api/lessons";

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _initHtmlViewer();
  }

  Future<void> _initHtmlViewer() async {
    if (!mounted) return;

    try {
      print('Initializing HtmlViewer with URL: ${widget.url}');

      // Check connectivity
      final connection = await Connectivity().checkConnectivity();
      _hasConnection = connection != ConnectivityResult.none;
      print('Connectivity: ${_hasConnection ? 'Online' : 'Offline'}');

      // Check if the URL is a local file path
      final isLocalUrl = widget.url.startsWith('file://') || (await File(widget.url).exists());
      print('Is local URL: $isLocalUrl (URL: ${widget.url})');

      if (isLocalUrl) {
        final localPath = widget.url.startsWith('file://') ? widget.url.substring(7) : widget.url;
        print('Loading local file: $localPath');
        await _loadLocalHtml(localPath);
      } else {
        final fullUrl = widget.url.startsWith('http') ? widget.url : '$baseUrl${widget.url.startsWith('/') ? '' : '/'}${widget.url}';
        print('Full URL: $fullUrl');

        if (_hasConnection) {
          if (!Uri.parse(fullUrl).isAbsolute) {
            setState(() {
              _isLoading = false;
              _errorMessage = _l10n?.errorLoadingData ?? 'Invalid URL: $fullUrl';
            });
            print('Invalid URL: $fullUrl');
            return;
          }
          await _loadOnlineHtml(fullUrl).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              setState(() {
                _isLoading = false;
                _errorMessage = _l10n?.errorLoadingData ?? 'Timeout loading $fullUrl';
              });
              print('Timeout loading $fullUrl');
            },
          );
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = _l10n?.errorLoadingData ?? 'No internet connection';
          });
          print('No internet connection');
        }
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load'}: $e';
        print('Error in _initHtmlViewer: $e\n$stackTrace');
      });
    }
  }

  Future<void> _loadOnlineHtml(String url) async {
    if (!mounted) return;

    try {
      print('Loading online HTML: $url');
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              print('WebView: Page started loading: $url');
              setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              print('WebView: Page finished loading: $url');
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              print('WebView error for $url: ${error.description}');
              setState(() {
                _isLoading = false;
                _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load'}: ${error.description}';
                _controller = null;
              });
            },
          ),
        );

      await controller.loadRequest(Uri.parse(url));
      setState(() {
        _controller = controller;
        _isLoading = true;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${_l10n?.couldNotLoadItem ?? 'Failed to load'}: $e';
        _controller = null;
        print('Error loading online HTML: $e\n$stackTrace');
      });
    }
  }

  Future<void> _loadLocalHtml(String path) async {
    if (!mounted) return;

    try {
      print('Loading local HTML: $path');
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _isLoading = false;
          _errorMessage = _l10n?.couldNotOpenFileError(path) ?? 'File not found: $path';
          _controller = null;
        });
        print('Local file not found: $path');
        return;
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              print('WebView: Local page started loading: $path');
              setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              print('WebView: Local page finished loading: $path');
              setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              print('WebView error for local file $path: ${error.description}');
              setState(() {
                _isLoading = false;
                _errorMessage = _l10n?.couldNotOpenFileError('$path: ${error.description}') ?? 'Failed to open file: $path - ${error.description}';
                _controller = null;
              });
            },
          ),
        );

      final fileUri = Uri.file(path).toString();
      print('Loading file URI: $fileUri');
      await controller.loadFile(fileUri);
      setState(() {
        _controller = controller;
        _isLoading = true;
      });
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
        _errorMessage = _l10n?.couldNotOpenFileError('$path: $e') ?? 'Failed to open file: $path - $e';
        _controller = null;
        print('Error loading local HTML: $e\n$stackTrace');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? Colors.white70 : AppColors.onSurfaceLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: dynamicOnSurfaceColor, fontSize: 16),
                  ),
                ],
              ),
            ),
          if (_controller != null && _errorMessage == null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(color: dynamicPrimaryColor),
              ),
            ),
        ],
      ),
    );
  }
}