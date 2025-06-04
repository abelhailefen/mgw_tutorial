import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';

class ExamViewerScreen extends StatefulWidget {
  static const routeName = '/exam-viewer';
  final String url;
  final String title;

  const ExamViewerScreen({super.key, required this.url, required this.title});

  @override
  State<ExamViewerScreen> createState() => _ExamViewerScreenState();
}

class _ExamViewerScreenState extends State<ExamViewerScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? specificError;
  AppLocalizations? _l10n; // Class-level l10n

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations.of(context); // Initialize l10n
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            specificError = _l10n!.couldNotLoadItem(widget.url); // Corrected usage
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicPrimaryColor = isDarkMode ? AppColors.primaryDark : AppColors.primaryLight;
    final dynamicOnSurfaceColor = isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
      ),
      body: Stack(
        children: [
          if (specificError != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    specificError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: dynamicOnSurfaceColor.withOpacity(0.7), fontSize: 16),
                  ),
                ],
              ),
            ),
          if (_controller != null && specificError == null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            Center(child: CircularProgressIndicator(color: dynamicPrimaryColor)),
        ],
      ),
    );
  }
}