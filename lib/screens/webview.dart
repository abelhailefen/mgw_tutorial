import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  final String url;
  final String title;

  Home({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final WebViewController _controller;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    // Ensure platform initialization for WebView
    //print(widget.url);

    // Decode and validate URL
    String decodedUrl = Uri.decodeFull(widget.url);
    String validatedUrl =
        decodedUrl.startsWith('http://') || decodedUrl.startsWith('https://')
            ? decodedUrl
            : 'https://$decodedUrl';

    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (String url) {
          _isLoading.value = true; // Show loading indicator
        },
        onPageFinished: (String url) {
          _isLoading.value = false; // Hide loading indicator
        },
      ))
      ..loadRequest(Uri.parse(validatedUrl));
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
              return isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.reload(); // Reload the current page
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
