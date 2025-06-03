import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';import 'package:webview_flutter/webview_flutter.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:provider/provider.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/utils/download_status.dart';
// import 'package:path_provider/path_provider.dart'; // Not directly needed here

class ExamViewerScreen extends StatefulWidget {
  static const routeName = '/exam-viewer';
  final String url; // Can be online URL or local file:// URL
  final String title;

  const ExamViewerScreen({super.key, required this.url, required this.title});

  @override
  State<ExamViewerScreen> createState() => _ExamViewerScreenState();
}

class _ExamViewerScreenState extends State<ExamViewerScreen> {
  WebViewController? _controller;
  bool _hasConnection = true; // Renamed to _canLoadContent below
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocalFile = false; // Track if we are loading a local file

  // Renamed _hasConnection to _canLoadContent for clarity
  // This now indicates if we have either network OR a valid local file
  bool get _canLoadContent => _hasConnection;


  @override
  void initState() {
    super.initState();
     // Pre-check download status to prime the ValueNotifier before build
     // This is important if the screen is opened directly to a potentially downloaded file
     WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
        final downloadId = lessonProvider.getDownloadIdByUrl(widget.url);
        if (downloadId != null) {
            // Calling getDownloadedFilePath updates the internal status notifier in MediaService
            // Corrected: Pass the URL to attachmentUrl when creating Lesson fallback
           await lessonProvider.getDownloadedFilePath(Lesson(
             id: 0,
             title: '',
             sectionId: 0,
             createdAt: DateTime.now(),
             updatedAt: DateTime.now(),
             attachmentUrl: widget.url, // Corrected: Pass the URL to attachmentUrl
             lessonTypeString: 'quiz',
           ));
        }
     });

    _checkConnectivityAndLoad();
  }

  // Helper to find the corresponding Lesson object from the provider
  // We find it by the htmlUrl (which uses attachmentUrl internally)
  Lesson? _findLesson(LessonProvider provider) {
     try {
      // Use firstWhereOrNull from collection package if available, otherwise fallback
      final allLessons = provider.getAllLessons();
      // Attempt to find the exact lesson by ID if possible first, then by URL
      // The getDownloadIdByUrl uses the htmlUrl getter which uses attachmentUrl
      final lessonById = allLessons.firstWhere(
          (lesson) => lesson.id.toString() == provider.getDownloadIdByUrl(widget.url), // Check ID matching derived download ID
          orElse: () => allLessons.firstWhere( // Fallback to checking htmlUrl
              (lesson) => lesson.htmlUrl == widget.url,
              orElse: () => Lesson( // Return a minimal fallback lesson if not found at all
                id: 0, title: widget.title, sectionId: 0,
                createdAt: DateTime.now(), updatedAt: DateTime.now(),
                lessonTypeString: 'quiz',
                attachmentUrl: widget.url, // Corrected: Pass the URL to attachmentUrl
              ),
            ),
          );
        // Return null if the fallback lesson has ID 0 (means it wasn't found)
        // This logic is slightly risky if a real lesson could have ID 0,
        // but given the typical lesson ID structure, it's a reasonable heuristic.
        // A more robust method would be to check against a specific "not found" marker Lesson or just return the found one.
         if (lessonById.id == 0 && (lessonById.attachmentUrl == null || lessonById.attachmentUrl != widget.url) && lessonById.title != widget.title) {
             return null; // It's likely just the default fallback if its props don't match the request
         }
        return lessonById;

     } catch (e) {
        print("Error finding lesson for URL ${widget.url}: $e");
        return null; // Return null if finding fails entirely
     }
  }

  Future<void> _checkConnectivityAndLoad() async {
    // Determine if the URL points to a local file based on its prefix
    _isLocalFile = widget.url.startsWith('file://');

    try {
      bool connectionOkay;
      String? filePath;

      if (_isLocalFile) {
         filePath = widget.url.replaceFirst('file://', '');
         // Check if the local file exists
         connectionOkay = await File(filePath).exists();
         print("Checking local file ${_isLocalFile}: File exists? $connectionOkay at path $filePath");
      } else {
        // Check network connectivity for online URLs
        final connectivityResult = await Connectivity().checkConnectivity(); // Connectivity() is correct here IF package is OK
        connectionOkay = connectivityResult != ConnectivityResult.none; // ConnectivityResult is correct here IF package is OK
         print("Checking network for online URL ${_isLocalFile}: Connected? $connectionOkay");
      }

      // Update state based on check result
      setState(() {
        _hasConnection = connectionOkay; // Update the internal flag
        if (_hasConnection) {
             // If connection is okay (either network or file exists), initialize WebView
            _initializeController(_isLocalFile ? filePath : widget.url); // Pass the correct path/URL
        } else {
            // No connection or file not found
           _isLoading = false;
           _errorMessage = _isLocalFile
               ? AppLocalizations.of(context)!.couldNotFindDownloadedFileError
               : AppLocalizations.of(context)!.errorLoadingData; // General network error
           print("Loading blocked. Error: $_errorMessage");
        }
      });


    } catch (e) {
      print("Error in _checkConnectivityAndLoad: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.errorLoadingData;
      });
    }
  }

  // Updated to accept the actual path/URL to load
  void _initializeController(String? urlToLoad) {
     if (urlToLoad == null || urlToLoad.isEmpty) {
        setState(() {
           _isLoading = false;
           _errorMessage = AppLocalizations.of(context)!.couldNotLoadItem(widget.url);
        });
        return;
     }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
             // print('WebView loading: $progress%'); // Optional: print progress
             // Only show loading indicator during initial load, or if progress jumps back (e.g., iframe load)
             if(_isLoading == false && progress < 100) {
                 setState(() { _isLoading = true; });
             } else if (_isLoading == true && progress == 100) {
                  setState(() { _isLoading = false; });
             }
          },
          onPageStarted: (String url) {
            print('WebView page started: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null; // Clear previous error
            });
          },
          onPageFinished: (String url) {
             print('WebView page finished: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView resource error: ${error.description} (Code: ${error.errorCode}, Type: ${error.errorType}) for URL: ${error.url}');
            setState(() {
              _isLoading = false;
              // Provide a more specific error message if possible
              String specificError = "${error.description} (Code: ${error.errorCode})";

              if (_isLocalFile) {
                  // Common error codes for file not found: -6 (Android), 404 (some WebViews)
                  if (error.errorCode == -6 || error.errorCode == 404) {
                     specificError = AppLocalizations.of(context)!.couldNotFindDownloadedFileError;
                  } else {
                     specificError = "${AppLocalizations.of(context)!.couldNotOpenDownloadedFileError}: ${error.description}"; // New/updated l10n key
                  }
              } else {
                 // Online resource error
                 specificError = "${AppLocalizations.of(context)!.couldNotLoadItem(widget.url)}: ${specificError}";
              }

              _errorMessage = specificError;
            });
          },
           onNavigationRequest: (NavigationRequest request) {
            // Allow navigation within the WebView
            return NavigationDecision.navigate;
          },
        ),
      );

    if (_isLocalFile) {
      print('Loading local file in WebView: $urlToLoad');
      // loadFile expects the path without 'file://'
      controller.loadFile(urlToLoad!.replaceFirst('file://', '')); // Use null assertion ! after check
    } else {
      print('Loading online URL in WebView: $urlToLoad');
      // Use parseStrict to potentially catch malformed URLs earlier
      controller.loadRequest(Uri.parse(urlToLoad!)); // Use null assertion ! after check
    }

    setState(() {
      _controller = controller;
    });
  }

  // Moved _downloadExam method outside the build method
  Future<void> _downloadExam(BuildContext context, Lesson? lesson, LessonProvider provider) async {
    final l10n = AppLocalizations.of(context)!;

    if (lesson == null) {
       print("Cannot download exam: Lesson object is null.");
       if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorLoadingData), // Or a more specific message
              backgroundColor: AppColors.error,
            ),
          );
       }
       return;
    }

    try {
      // The provider handles finding the correct download ID and starting the download
      await provider.startDownload(lesson);

      // Start the download animation/progress display immediately by notifying listeners
      // The ValueListenableBuilder in the AppBar will pick this up.
      // We don't need a specific success snackbar here, as the progress indicator appears.
      // A success snackbar might be redundant or appear too quickly.
      // The status change to Downloaded will handle the UI update.


    } catch (e) {
      print("Error starting download for exam ${lesson.title}: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.downloadFailedTooltip), // Use failed tooltip for the error
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final lessonProvider = Provider.of<LessonProvider>(context);

    // Get the download ID for the current exam URL
    final downloadId = lessonProvider.getDownloadIdByUrl(widget.url);
    // Find the lesson object. Needed for start/cancel/delete methods.
    final currentLesson = _findLesson(lessonProvider);


    // Use theme colors for AppBar elements - Corrected using existing AppColors
    final appBarTitleColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;
    final appBarIconColor = isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight;


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: appBarTitleColor)),
        backgroundColor: isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight,
        iconTheme: IconThemeData(color: appBarIconColor),
        actions: [
           // Only show actions if a download ID can be determined AND the lesson object is found
          if (downloadId != null && currentLesson != null)
            ValueListenableBuilder<DownloadStatus>(
              valueListenable: lessonProvider.getDownloadStatusNotifier(downloadId),
              builder: (context, status, child) {
                final downloadActionIconColor = isDarkMode ? AppColors.secondaryDark : AppColors.secondaryLight;
                final deleteActionIconColor = (isDarkMode ? AppColors.iconDark : AppColors.iconLight).withOpacity(0.6);

                switch (status) {
                  case DownloadStatus.notDownloaded:
                  case DownloadStatus.failed: // Offer retry on failure
                  case DownloadStatus.cancelled: // Offer retry/download after cancel
                    // Only show download if the URL is not already a local file path
                    if (!_isLocalFile) {
                       return IconButton(
                        icon: Icon(Icons.download_for_offline_outlined, color: downloadActionIconColor),
                        tooltip: l10n.downloadQuizTooltip,
                        onPressed: () {
                           print("AppBar Download button pressed for ID: $downloadId");
                           _downloadExam(context, currentLesson, lessonProvider);
                        },
                      );
                    } else {
                        // If it's a local file and status is not downloaded/failed/cancelled,
                        // it means we loaded it, but the status somehow isn't 'downloaded' yet in notifiers.
                        // This state might need debugging, but hide the button for now.
                        return const SizedBox.shrink();
                    }

                  case DownloadStatus.downloading:
                    return ValueListenableBuilder<double>(
                      valueListenable: lessonProvider.getDownloadProgressNotifier(downloadId),
                      builder: (context, progress, _) {
                        final safeProgress = progress.clamp(0.0, 1.0);
                        final progressText = safeProgress > 0 && safeProgress < 1 ? "${(safeProgress * 100).toInt()}%" : "";
                        return SizedBox( // Wrap Stack in SizedBox for consistent sizing
                          width: 40, // Match other icon button sizes
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 28, // Match size in LessonListScreen
                                height: 28, // Match size in LessonListScreen
                                child: CircularProgressIndicator(
                                  value: safeProgress > 0 ? safeProgress : null,
                                  strokeWidth: 3.0,
                                  backgroundColor: appBarIconColor.withOpacity(0.1),
                                  color: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                                ),
                              ),
                               if (progressText.isNotEmpty)
                                  Text(
                                    progressText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: appBarTitleColor
                                    ),
                                  ),
                              Positioned( // Cancel button overlay
                                right: -8, // Adjust position
                                top: -8,
                                 child: IconButton(
                                   icon: Icon(Icons.cancel, size: 18, color: AppColors.error),
                                   padding: EdgeInsets.zero,
                                   tooltip: l10n.cancelDownloadTooltip,
                                   onPressed: () {
                                      print("AppBar Cancel download pressed for ID: $downloadId");
                                      lessonProvider.cancelDownload(currentLesson);
                                   },
                                 ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  case DownloadStatus.downloaded:
                    // Show delete button ONLY if the current URL being viewed
                    // is the local downloaded file path.
                    // We need to get the actual downloaded path to compare.
                    final downloadedPath = lessonProvider.getDownloadedFilePath(currentLesson); // This is async, will need FutureBuilder or state
                    // For simplicity here, we'll assume if status is downloaded, the file exists at the stored path.
                    // A more robust solution would involve checking the file existence synchronously if possible or using state management.
                    // Let's refine this: check if the current widget.url IS a file:// URL AND the status is downloaded.
                     if (_isLocalFile) {
                        return IconButton(
                          icon: Icon(Icons.delete_outline, color: deleteActionIconColor),
                          tooltip: l10n.deleteDownloadedFileTooltip,
                          onPressed: () {
                             print("AppBar Delete button pressed for ID: $downloadId");
                             lessonProvider.deleteDownload(currentLesson, context);
                             // After deletion, navigate back as the current content source is gone
                             Navigator.of(context).pop();
                          },
                        );
                     } else {
                         // If status is downloaded, but we are viewing an online URL,
                         // it means the user downloaded while viewing online.
                         // The delete button should appear if the status is downloaded,
                         // regardless of whether they are currently viewing online or local.
                         // Let's revert to showing delete if status is downloaded.
                         return IconButton(
                            icon: Icon(Icons.delete_outline, color: deleteActionIconColor),
                            tooltip: l10n.deleteDownloadedFileTooltip,
                            onPressed: () async {
                               print("AppBar Delete button pressed for ID: $downloadId (viewing online)");
                               await lessonProvider.deleteDownload(currentLesson, context);
                               // Stay on the page (viewing online version)
                            },
                          );
                     }
                }
              },
            ),
        ],
      ),
      body: _isLoading
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
                        // Show retry button if it's an online URL that failed OR a general error
                         if(!_isLocalFile || (_isLocalFile && _errorMessage != AppLocalizations.of(context)!.couldNotFindDownloadedFileError))
                            ElevatedButton(
                              onPressed: _isLoading ? null : _checkConnectivityAndLoad,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                                foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                              ),
                              child: Text(l10n.retry),
                            ),
                         // If local file not found AND it's a downloadable quiz, show download button
                         // Ensure currentLesson is not null and downloadId exists for downloading
                         if(_isLocalFile && _errorMessage == AppLocalizations.of(context)!.couldNotFindDownloadedFileError && downloadId != null && currentLesson != null)
                            ElevatedButton.icon(
                              icon: Icon(Icons.download_for_offline_outlined, color: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight),
                              label: Text(l10n.downloadQuizTooltip),
                              onPressed: _isLoading ? null : () => _downloadExam(context, currentLesson, lessonProvider), // Disable while loading
                               style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? AppColors.primaryDark : AppColors.primaryLight,
                                foregroundColor: isDarkMode ? AppColors.onPrimaryDark : AppColors.onPrimaryLight,
                              ),
                            ),
                      ],
                    ),
                  ),
                )
              : _controller != null
                  ? WebViewWidget(controller: _controller!)
                  : Center(child: Text(l10n.errorLoadingData)), // Fallback if controller is null
    );
  }
}
