import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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
  bool _isDownloaded = false;
  bool _isDownloading = false;
  String? _errorMessage;
  String? _localFilePath;
  AppLocalizations? _l10n; // Class-level l10n

  static String baseUrl = "https://lessonservice.amtprinting19.com/api/lessons";

  @override
  void initState() {
    super.initState();
    _initHtmlViewer();
  }

  Future<void> _initHtmlViewer() async {
    _l10n = AppLocalizations.of(context); // Initialize l10n
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final connection = await Connectivity().checkConnectivity();
    _hasConnection = connection != ConnectivityResult.none;

    // Check if the URL is a local file path
    final isLocalUrl = widget.url.startsWith('/');

    if (isLocalUrl) {
      _isDownloaded = true;
      _localFilePath = widget.url;
      _loadLocalHtml(_localFilePath!);
    } else {
      final fullUrl = widget.url.startsWith('http') ? widget.url : '$baseUrl${widget.url}';
      final hash = md5.convert(utf8.encode(fullUrl)).toString();
      final fileName = '${widget.title.replaceAll(" ", "_")}_$hash.html';

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      final exists = await file.exists();

      if (exists) {
        _isDownloaded = true;
        _localFilePath = filePath;
        _loadLocalHtml(_localFilePath!);
      } else if (_hasConnection) {
        _loadOnlineHtml(fullUrl);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = _l10n!.errorLoadingData; // Use existing key
        });
      }
    }
  }

  void _loadOnlineHtml(String url) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _errorMessage = _l10n!.couldNotLoadItem(url); // Use existing key
          }),
        ),
      )
      ..loadRequest(Uri.parse(url));

    setState(() {
      _controller = controller;
      _isLoading = true;
    });
  }

  void _loadLocalHtml(String path) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _isLoading = false;
            _errorMessage = _l10n!.couldNotOpenFileError(path); // Use existing key
          }),
        ),
      )
      ..loadFile(path);

    setState(() {
      _controller = controller;
      _isLoading = true;
    });
  }

  Future<void> _downloadHtml() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    setState(() {
      _isDownloading = true;
    });

    final fullUrl = widget.url.startsWith('http') ? widget.url : '$baseUrl${widget.url}';
    final hash = md5.convert(utf8.encode(fullUrl)).toString();
    final fileName = '${widget.title.replaceAll(" ", "_")}_$hash.html';

    try {
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n!.fileDownloadedTooltip), // Use existing key
            backgroundColor: isDarkMode ? AppColors.secondaryContainerDark : AppColors.secondaryContainerLight,
          ),
        );

        setState(() {
          _isDownloaded = true;
          _localFilePath = file.path;
        });

        if (!_hasConnection) {
          _loadLocalHtml(file.path);
        }
      } else {
        throw Exception('Status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l10n!.couldNotLoadItem(e.toString())), // Use existing key
          backgroundColor: AppColors.errorContainer,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        actions: [
          if (_hasConnection && !_isDownloaded)
            ElevatedButton(
              onPressed: _isDownloading ? null : _downloadHtml,
              style: ElevatedButton.styleFrom(
                backgroundColor: dynamicPrimaryColor,
                foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
              ),
              child: Text(l10n.downloadExamTooltip), // Use existing key
            ),
        ],
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
                    style: TextStyle(color: dynamicOnSurfaceColor.withOpacity(0.7), fontSize: 16),
                  ),
                  if (_hasConnection && !_isDownloaded) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadHtml,
                      icon: Icon(Icons.download, color: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight),
                      label: Text(l10n.downloadExamTooltip), // Use existing key
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dynamicPrimaryColor,
                        foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_controller != null && _errorMessage == null) WebViewWidget(controller: _controller!),
          if (_isLoading || _isDownloading)
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