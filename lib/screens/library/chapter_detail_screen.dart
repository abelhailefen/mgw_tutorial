// lib/screens/library/chapter_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mgw_tutorial/l10n/app_localizations.dart';
class ChapterDetailScreen extends StatelessWidget {
  static const routeName = '/chapter-detail';

  final String subjectTitle;
  final Map<String, dynamic> chapter;

  const ChapterDetailScreen({
    super.key,
    required this.subjectTitle,
    required this.chapter,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(l10n.appTitle.contains("መጂወ") ? "$urlString መክፈት አልተቻለም።" : 'Could not launch $urlString'),
              backgroundColor: theme.colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final List<dynamic> videosRaw = chapter['videos'] as List<dynamic>? ?? [];
    final List<Map<String, String>> videos = videosRaw.map((v) {
      if (v is Map) {
        return {
          'title': v['title']?.toString() ?? (l10n.appTitle.contains("መጂወ") ? "ርዕስ አልባ ቪዲዮ" : 'Untitled Video'),
          'description': v['description']?.toString() ?? '',
          'url': v['url']?.toString(),
        };
      }
      return {'title': (l10n.appTitle.contains("መጂወ") ? "የማይሰራ የቪዲዮ መረጃ" : 'Invalid Video Data'), 'description': ''};
    }).toList();

    final String notesContent = (chapter['notes'] is String
            ? chapter['notes']
            : (chapter['notes'] is Map ? chapter['notes']['content']?.toString() : null)) ??
        (l10n.appTitle.contains("መጂወ") ? "ለዚህ ምዕራፍ ምንም ማስታወሻዎች የሉም።" : 'No notes available for this chapter yet.');

    final List<dynamic> pdfsRaw = chapter['pdfs'] as List<dynamic>? ?? [];
    final List<Map<String, String>> pdfs = pdfsRaw.map((p) {
      if (p is Map) {
        return {
          'title': p['title']?.toString() ?? (l10n.appTitle.contains("መጂወ") ? "ርዕስ አልባ ፒዲኤፍ" : 'Untitled PDF'),
          'url': p['url']?.toString() ?? '',
        };
      }
      return {'title': (l10n.appTitle.contains("መጂወ") ? "የማይሰራ የፒዲኤፍ መረጃ" : 'Invalid PDF Data'), 'url': ''};
    }).toList();

    final List<dynamic> examsRaw = chapter['exams'] as List<dynamic>? ?? [];
    final List<Map<String, dynamic>> exams = examsRaw.map((e) {
      if (e is Map) {
        return {
          'title': e['title']?.toString() ?? (l10n.appTitle.contains("መጂወ") ? "ርዕስ አልባ ፈተና" : 'Untitled Exam'),
          'questionCount': e['questionCount'] as int?,
          'id': e['id']?.toString(),
        };
      }
      return {'title': (l10n.appTitle.contains("መጂወ") ? "የማይሰራ የፈተና መረጃ" : 'Invalid Exam Data')};
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(chapter['title'] ?? (l10n.appTitle.contains("መጂወ") ? "ምዕራፍ ዝርዝሮች" : 'Chapter Details')),
          bottom: TabBar(
            isScrollable: false,
            labelColor: theme.tabBarTheme.labelColor ?? theme.colorScheme.primary,
            unselectedLabelColor: theme.tabBarTheme.unselectedLabelColor ?? theme.colorScheme.onSurface.withOpacity(0.7),
            indicatorColor: theme.tabBarTheme.indicatorColor ?? theme.colorScheme.primary,
            tabs: [
              Tab(icon: const Icon(Icons.videocam_outlined), text: l10n.appTitle.contains("መጂወ") ? "ቪዲዮዎች" : 'Videos'),
              Tab(icon: const Icon(Icons.notes_outlined), text: l10n.appTitle.contains("መጂወ") ? "ማስታወሻዎች" : 'Notes'),
              Tab(icon: const Icon(Icons.picture_as_pdf_outlined), text: l10n.appTitle.contains("መጂወ") ? "ፒዲኤፎች" : 'PDF'),
              Tab(icon: const Icon(Icons.quiz_outlined), text: l10n.appTitle.contains("መጂወ") ? "ፈተናዎች" : 'Exams'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVideoList(context, videos, l10n, theme),
            _buildNotesView(context, notesContent, l10n, theme),
            _buildPdfList(context, pdfs, l10n, theme),
            _buildExamList(context, exams, l10n, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList(BuildContext context, List<Map<String, String>> videos, AppLocalizations l10n, ThemeData theme) {
    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.appTitle.contains("መጂወ") ? "ለዚህ ምዕራፍ ምንም ቪዲዮዎች የሉም።" : 'No videos available for this chapter yet.', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: videos.length,
      itemBuilder: (ctx, index) {
        final video = videos[index];
        return Card( // Uses CardTheme
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary, size: 40),
            title: Text(video['title']!, style: theme.textTheme.titleSmall),
            subtitle: video['description']!.isNotEmpty ? Text(video['description']!, style: theme.textTheme.bodySmall) : null,
            onTap: () {
              if (video['url'] != null && video['url']!.isNotEmpty) {
                 _launchUrl(context, video['url']!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.appTitle.contains("መጂወ") ? "ለ '${video['title']}' የቪዲዮ ማጫወቻ ገና አልተተገበረም።" : 'Video player for "${video['title']}" not implemented yet.'),
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesView(BuildContext context, String notesContent, AppLocalizations l10n, ThemeData theme) {
    if (notesContent == (l10n.appTitle.contains("መጂወ") ? "ለዚህ ምዕራፍ ምንም ማስታወሻዎች የሉም።" : 'No notes available for this chapter yet.')) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_snippet_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(notesContent, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        notesContent,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildPdfList(BuildContext context, List<Map<String, String>> pdfs, AppLocalizations l10n, ThemeData theme) {
    if (pdfs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.appTitle.contains("መጂወ") ? "ለዚህ ምዕራፍ ምንም ፒዲኤፎች የሉም።" : 'No PDFs available for this chapter yet.', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pdfs.length,
      itemBuilder: (ctx, index) {
        final pdf = pdfs[index];
        return Card( // Uses CardTheme
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.description_outlined, color: theme.colorScheme.error, size: 40), // Or secondary
            title: Text(pdf['title']!, style: theme.textTheme.titleSmall),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.6)),
            onTap: () {
              if (pdf['url'] != null && pdf['url']!.isNotEmpty) {
                _launchUrl(context, pdf['url']!);
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.appTitle.contains("መጂወ") ? "ለ '${pdf['title']}' የፒዲኤፍ ማያያዣ ጠፍቷል።" : 'PDF link for "${pdf['title']}" is missing.'),
                      backgroundColor: theme.colorScheme.errorContainer,
                      behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildExamList(BuildContext context, List<Map<String, dynamic>> exams, AppLocalizations l10n, ThemeData theme) {
    if (exams.isEmpty) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 60, color: theme.iconTheme.color?.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(l10n.appTitle.contains("መጂወ") ? "ለዚህ ምዕራፍ ምንም ፈተናዎች የሉም።" : 'No exams available for this chapter yet.', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: exams.length,
      itemBuilder: (ctx, index) {
        final exam = exams[index];
        return Card( // Uses CardTheme
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.assignment_turned_in_outlined, color: theme.colorScheme.secondary, size: 40), // Or success color
            title: Text(exam['title']!, style: theme.textTheme.titleSmall),
            subtitle: exam['questionCount'] != null ? Text(l10n.appTitle.contains("መጂወ") ? 'ጥያቄዎች: ${exam['questionCount']}' : 'Questions: ${exam['questionCount']}', style: theme.textTheme.bodySmall) : null,
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.iconTheme.color?.withOpacity(0.6)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.appTitle.contains("መጂወ") ? "ለ '${exam['title']}' የፈተና ገጽ ገና አልተተገበረም።" : 'Exam screen for "${exam['title']}" not implemented yet.'),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        );
      },
    );
  }
}