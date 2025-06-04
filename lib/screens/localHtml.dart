
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LocalHtmlViewer extends StatefulWidget {
  final String localHtmlPath; // Path to the local HTML file
  final String title;

  LocalHtmlViewer({Key? key, required this.localHtmlPath, required this.title})
      : super(key: key);

  @override
  _LocalHtmlViewerState createState() => _LocalHtmlViewerState();
}

class _LocalHtmlViewerState extends State<LocalHtmlViewer> {
  late final WebViewController _controller;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          _isLoading.value = true;
        },
        onPageFinished: (String url) {
          _isLoading.value = false;
        },
      ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocalHtml(widget.localHtmlPath);
    });
  }

  Future<void> _loadLocalHtml(String localHtmlPath) async {
    final file = File(localHtmlPath);
    if (await file.exists()) {
      final fileUri = Uri.file(localHtmlPath).toString();
      _controller.loadFile(fileUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('HTML file not found at $localHtmlPath')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          ValueListenableBuilder<bool>(
            valueListenable: _isLoading,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
