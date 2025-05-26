// lib/utils/download_status.dart

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
  cancelled, // Added cancelled state for completeness
}