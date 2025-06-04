import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
     _initializeLoading(widget.url);
  }

  Future<void> _initializeLoading(String urlToLoad) async {
      if (!mounted) return;

      final isLocalFile = urlToLoad.startsWith('file://');

       if (!isLocalFile) {
            try {
              final connectivityResult = await Connectivity().checkConnectivity();
              final hasNetwork = connectivityResult != ConnectivityResult.none;

              if (!hasNetwork) {
                   if (mounted) {
                       setState(() {
                           _isLoading = false;
                           _errorMessage = AppLocalizations.of(context)!.errorLoadingData;
                       });
                   }
                   return;
              }
            } catch (e) {
                 if (mounted) {
                       setState(() {
                           _isLoading = false;
                           _errorMessage = AppLocalizations.of(context)!.errorLoadingData;
                       });
                   }
                   return;
            }
       } else {
           final localPath = urlToLoad.replaceFirst('file://', '');
           final file = File(localPath);
           if (!await file.exists()) {
               if (mounted) {
                    setState(() {
                        _isLoading = false;
                        _errorMessage = AppLocalizations.of(context)!.couldNotFindDownloadedFileError;
                    });
                }
               return;
           }
       }

       _initializeController(urlToLoad);
  }

  void _initializeController(String urlToLoad) {
     if (!mounted) return;

     setState(() {
        _isLoading = true;
        _errorMessage = null;
     });

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
              if (!mounted) return;
             if(_isLoading == false && progress < 100 && progress > 10) {
                 setState(() { _isLoading = true; });
             } else if (_isLoading == true && progress == 100) {
                  setState(() { _isLoading = false; });
             }
          },
          onPageStarted: (String url) {
             if (!mounted) return;
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
              if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
             if (!mounted) return;
            setState(() {
              _isLoading = false;
              final bool errorIsLocal = widget.url.startsWith('file://');

              String specificError = "${error.description} (Code: ${error.errorCode})";

              if (errorIsLocal) {
                  if (error.errorCode == -6 || error.errorCode == 404) {
                     specificError = AppLocalizations.of(context)!.couldNotFindDownloadedFileError;
                  } else {
                     specificError = "${AppLocalizations.of(context)!.errorLoadingData}: ${error.description}";
                  }
              } else {
                 specificError = "${AppLocalizations.of(context)!.couldNotLoadItem(widget.url)}: ${specificError}";
              }
              _errorMessage = specificError;
            });
          },
           onNavigationRequest: (NavigationRequest request) async {
             if (!mounted) return NavigationDecision.prevent;

             final initialUri = Uri.tryParse(widget.url);
             final requestUri = Uri.tryParse(request.url);

             bool isExternal = false;
             if (requestUri != null) {
                 if (initialUri != null && (requestUri.scheme != initialUri.scheme || (requestUri.scheme == 'http' || requestUri.scheme == 'https') && requestUri.host != initialUri.host)) {
                     isExternal = true;
                 } else if (requestUri.scheme != 'http' && requestUri.scheme != 'https' && requestUri.scheme != 'file' && request.url != 'about:blank') {
                     isExternal = true;
                 }
             }

            if (isExternal) {
                if (await canLaunchUrl(Uri.parse(request.url))) {
                   launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
                   return NavigationDecision.prevent;
                } else {
                    if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text(AppLocalizations.of(context)!.errorLoadingData),
                             backgroundColor: AppColors.errorContainer,
                           ),
                        );
                    }
                    return NavigationDecision.prevent;
                }
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (urlToLoad.startsWith('file://')) {
      controller.loadFile(urlToLoad.replaceFirst('file://', ''));
    } else {
      controller.loadRequest(Uri.parse(urlToLoad));
    }

     if (mounted) {
        setState(() {
          _controller = controller;
        });
     }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final appBarTitleColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;
    final appBarIconColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: appBarTitleColor), overflow: TextOverflow.ellipsis),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        iconTheme: IconThemeData(color: appBarIconColor),
        actions: [],
      ),
      body: _isLoading && _controller == null && _errorMessage == null
          ? Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                     padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                         ElevatedButton(
                           onPressed: _isLoading ? null : () => _initializeLoading(widget.url),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                             foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                           ),
                           child: Text(l10n.retry),
                         ),
                      ],
                    ),
                  ),
                )
              : _controller != null
                  ? Stack(
                      children: [
                        WebViewWidget(controller: _controller!),
                        if (_isLoading)
                           Center(child: CircularProgressIndicator(color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight)),
                      ],
                    )
                  : Center(child: Text(l10n.errorLoadingData)),
    );
  }
}