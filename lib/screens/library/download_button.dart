import 'package:flutter/material.dart';
import 'package:mgw_tutorial/models/lesson.dart';
import 'package:mgw_tutorial/provider/lesson_provider.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'package:mgw_tutorial/utils/download_status.dart';

class DownloadButton extends StatelessWidget {
  final Lesson lesson;
  final LessonProvider provider;
  final int sectionId;

  const DownloadButton({
    super.key,
    required this.lesson,
    required this.provider,
    required this.sectionId,
  });

  @override
  Widget build(BuildContext context) {
    final downloadId = provider.getDownloadId(lesson);
    if (downloadId == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<DownloadStatus>(
          valueListenable: provider.getDownloadStatusNotifier(downloadId),
          builder: (ctx, status, _) {
            switch (status) {
              case DownloadStatus.downloaded:
                return IconButton(
                  icon: Icon(Icons.check_circle, color: iconColor),
                  tooltip: "Downloaded",
                  onPressed: () {},
                  onLongPress: () {
                    provider.deleteDownload(lesson, context);
                  },
                );

              case DownloadStatus.downloading:
                return ValueListenableBuilder<double>(
                  valueListenable: provider.getDownloadProgressNotifier(downloadId),
                  builder: (ctx, progress, _) {
                    final safeProgress = progress.clamp(0.0, 1.0);
                    final percent = (safeProgress * 100).toInt();
                    return GestureDetector(
                      onLongPress: () => provider.cancelDownload(lesson),
                      child: Row(
                        children: [
                          const Icon(Icons.downloading),
                          const SizedBox(width: 6),
                          Text("$percent%", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    );
                  },
                );

              default:
                return IconButton(
                  icon: Icon(Icons.download, color: iconColor),
                  tooltip: "Download",
                  onPressed: () async {
                    provider.getDownloadStatusNotifier(downloadId).value = DownloadStatus.downloading;
                    await provider.startDownload(lesson);
                  },
                );
            }
          },
        ),
        ValueListenableBuilder<DownloadStatus>(
          valueListenable: provider.getDownloadStatusNotifier(downloadId),
          builder: (ctx, status, _) {
            if (status == DownloadStatus.downloading) {
              return ValueListenableBuilder<double>(
                valueListenable: provider.getDownloadProgressNotifier(downloadId),
                builder: (ctx, progress, _) {
                  final safeProgress = progress.clamp(0.0, 1.0);
                  final percent = (safeProgress * 100).toInt();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 6,
                          backgroundColor: iconColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(iconColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Downloading... $percent%",
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
