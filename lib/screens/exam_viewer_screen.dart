import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/utils/download_status.dart';

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
  bool _hasConnection = true;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivityAndLoad();
  }

  Future<void> _checkConnectivityAndLoad() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _hasConnection = connectivityResult != ConnectivityResult.none;
      if (_hasConnection || widget.url.startsWith('file://')) {
        _initializeController();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = AppLocalizations.of(context)!.errorLoadingData;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.errorLoadingData;
      });
    }
  }

  void _initializeController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _errorMessage = AppLocalizations.of(context)!.couldNotLaunchItem(widget.url);
            });
          },
        ),
      );

    if (widget.url.startsWith('file://')) {
      controller.loadFile(widget.url.replaceFirst('file://', ''));
    } else {
      controller.loadRequest(Uri.parse(widget.url));
    }

    setState(() {
      _controller = controller;
    });
  }

  Future<void> _downloadExam(BuildContext context, LessonProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final lesson = provider.getAllLessons().firstWhere(
            (lesson) => lesson.htmlUrl == widget.url,
            orElse: () => Lesson(
              id: 0,
              title: widget.title,
              sectionId: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              lessonTypeString: 'quiz',
              attachmentUrl: widget.url,
            ),
          );
      await provider.startDownload(lesson);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.downloadExamTooltip),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLoadingData),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final downloadId = lessonProvider.getDownloadIdByUrl(widget.url);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: AppColors.onPrimaryLight)),
        backgroundColor: AppColors.appBarBackgroundLight,
        iconTheme: IconThemeData(color: AppColors.onPrimaryLight),
        actions: [
          if (_hasConnection && downloadId != null)
            ValueListenableBuilder<DownloadStatus>(
              valueListenable: lessonProvider.getDownloadStatusNotifier(downloadId),
              builder: (context, status, child) {
                return ValueListenableBuilder<double>(
                  valueListenable: lessonProvider.getDownloadProgressNotifier(downloadId),
                  builder: (context, progress, child) {
                    switch (status) {
                      case DownloadStatus.notDownloaded:
                      case DownloadStatus.failed:
                      case DownloadStatus.cancelled:
                        return IconButton(
                          icon: Icon(Icons.download, color: AppColors.downloadIconColor),
                          tooltip: l10n.downloadExamTooltip,
                          onPressed: () => _downloadExam(context, lessonProvider),
                        );
                      case DownloadStatus.downloading:
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 2,
                            color: AppColors.downloadProgressColor,
                          ),
                        );
                      case DownloadStatus.downloaded:
                        return IconButton(
                          icon: Icon(Icons.delete, color: AppColors.deleteIconColor),
                          tooltip: l10n.deleteExamTooltip,
                          onPressed: () {
                            final lesson = lessonProvider.getAllLessons().firstWhere(
                                  (lesson) => lesson.htmlUrl == widget.url,
                                  orElse: () => Lesson(
                                    id: 0,
                                    title: widget.title,
                                    sectionId: 0,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    lessonTypeString: 'quiz',
                                    attachmentUrl: widget.url,
                                  ),
                                );
                            lessonProvider.deleteDownload(lesson, context);
                          },
                        );
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkConnectivityAndLoad,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryLight,
                          foregroundColor: AppColors.onPrimaryLight,
                        ),
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : _controller != null
                  ? WebViewWidget(controller: _controller!)
                  : Center(child: Text(l10n.errorLoadingData)),
    );
  }
}