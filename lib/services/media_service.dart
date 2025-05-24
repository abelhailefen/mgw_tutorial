import 'dart:io';
import 'package:dio/dio.dart';
// import 'package:flutter/material.dart'; // <-- Remove this if deleteFile doesn't need context
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MediaService {
  static final _dio = Dio();
  static const _secureStorage = FlutterSecureStorage();

  // Get the file path for storing the media
  static Future<String> _getFilePath(String id, String fileExtension) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$id.$fileExtension';
  }

  // Check if a file is already downloaded
  static Future<bool> isFileDownloaded(String id) async {
    try {
      final storedPath = await _secureStorage.read(key: id);
      // print("Checking if file is downloaded for ID: $id, storedPath: $storedPath"); // Optional: keep print for debugging
      if (storedPath != null) {
        final file = File(storedPath);
        final exists = file.existsSync();
        // print("File exists: $exists for path: $storedPath"); // Optional: keep print for debugging
        return exists;
      }
      return false;
    } catch (e) {
      print("Error checking if file is downloaded for ID $id: $e");
      return false;
    }
  }

  // Download a YouTube video
  // Returns the file path if successful, null otherwise
  static Future<String?> downloadVideoFile({
    required String videoId, // Use the already parsed clean ID
    required String url,
    required Function(double) onProgress,
    CancelToken? cancelToken, // Add CancelToken parameter
  }) async {
    if (url.isEmpty) {
      print("Error: Empty video URL for ID $videoId");
      return null;
    }

    final yt = YoutubeExplode();
    try {
      // Note: url is already split by ';' in the provider.
      // We now expect videoId to be passed directly here.
      // If url still needs parsing here, do it:
      // final video = await yt.videos.get(url);
      // final cleanVideoId = video.id.value; // Re-parse if needed, but provider should do this

      // Use the clean videoId passed in
      final manifest = await yt.videos.streamsClient.getManifest(videoId,
          ytClients: [YoutubeApiClient.safari, YoutubeApiClient.androidVr]); // Using alternative clients

      // Prefer muxed stream if available
      if (manifest.muxed.isNotEmpty) {
        final muxedStream = manifest.muxed.withHighestBitrate();
        final fileExtension = muxedStream.container.name; // e.g., 'mp4'
        final videoFilePath = await _getFilePath(videoId, fileExtension);

        await _dio.download(
          muxedStream.url.toString(),
          videoFilePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = received / total;
              onProgress(progress);
            }
          },
        );

        await _secureStorage.write(key: videoId, value: videoFilePath);
        print("Video downloaded successfully for ID $videoId to $videoFilePath");
        return videoFilePath;
      } else {
         // Fallback to audio + video if no muxed stream?
         // This requires merging streams, which is more complex.
         // For now, if no muxed stream, consider it a failure to download.
         print("No muxed streams available for video ID: $videoId");
         return null;
      }
    } on DioException catch(e) {
       if (CancelToken.isCancel(e)) {
          print("Download cancelled for ID $videoId: ${e.message}");
       } else {
          print("Dio Error downloading video for ID $videoId: ${e.message}");
          if (e.response != null) {
             print("Dio Error Response Status: ${e.response?.statusCode}");
             print("Dio Error Response Data: ${e.response?.data}");
          }
       }
       // Clean up potential partial file if download failed/cancelled unexpectedly
       final partialPath = await _getFilePath(videoId, 'partial'); // Assume a default extension for cleanup attempt
        if (await File(partialPath).exists()) {
            try { await File(partialPath).delete(); } catch(_) {}
        }


       return null; // Indicate failure
    } catch (e, s) {
      print("Error downloading video for ID $videoId: $e");
      print(s); // Print stack trace for generic errors
      return null; // Indicate failure
    } finally {
      yt.close(); // Close youtube_explode_dart client
    }
  }

  // Download an image - Keep this as is or update path logic if needed
  // Returns the file path if successful, null otherwise
  static Future<String?> downloadImageFile({
    required String imageId,
    required String url,
    required Function(double) onProgress,
    CancelToken? cancelToken, // Add CancelToken parameter
  }) async {
    if (url.isEmpty) {
      print("Error: Empty image URL for ID $imageId");
      return null;
    }

    try {
      // Use the provided imageId directly, assuming it's clean or make it so.
      // final cleanImageId = imageId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ''); // Keep if necessary
      final fileExtension = url.split('.').last.toLowerCase();
      // Basic validation for extension
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
         print("Warning: Unexpected image file extension: $fileExtension for $url. Using '.jpg'.");
         // Consider defaulting or failing if extension is weird
         // For robustness, you might fetch headers first to get content-type
         // For now, let's proceed but maybe force .jpg
         // fileExtension = 'jpg'; // uncomment to force
      }
      final imageFilePath = await _getFilePath(imageId, fileExtension);


      await _dio.download(
        url,
        imageFilePath,
        cancelToken: cancelToken, // Pass CancelToken to Dio
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      await _secureStorage.write(key: imageId, value: imageFilePath);
      print("Image downloaded successfully for ID $imageId: $imageFilePath");
      return imageFilePath;
    } on DioException catch(e) {
         if (CancelToken.isCancel(e)) {
            print("Image download cancelled for ID $imageId: ${e.message}");
         } else {
            print("Dio Error downloading image for ID $imageId: ${e.message}");
         }
         return null;
    } catch (e, s) {
      print("Error downloading image for ID $imageId: $e");
      print(s);
      return null;
    }
  }


  // Retrieve a file's local path
  static Future<String?> getSecurePath(String id) async {
    try {
      final path = await _secureStorage.read(key: id);
      return path;
    } catch (e) {
      print("Error getting secure path for ID $id: $e");
      return null;
    }
  }

  // Delete a downloaded file and its secure storage entry
  // Returns true if deletion was attempted (file existed or storage entry existed), false otherwise
  static Future<bool> deleteFile(String id) async {
    try {
      final storedPath = await _secureStorage.read(key: id);
      bool attemptedDeletion = false;

      if (storedPath != null) {
        attemptedDeletion = true;
        final file = File(storedPath);
        if (await file.exists()) {
          await file.delete();
          print("File deleted successfully for ID: $id at path $storedPath");
        } else {
           print("File not found at stored path for ID: $id ($storedPath)");
        }
      } else {
         print("No stored path found for ID: $id");
      }

      // Always attempt to delete the secure storage key
       await _secureStorage.delete(key: id);
       print("Secure storage key deleted for ID: $id");


      return attemptedDeletion || storedPath != null; // Return true if we had a path or key to delete
    } catch (e) {
      print("Error deleting file for ID $id: $e");
      return false; // Indicate failure
    }
  }

  // Retrieve all downloaded files (IDs mapped to paths)
  static Future<Map<String, String>> getAllDownloadedFiles() async {
    try {
      final allEntries = await _secureStorage.readAll();
      final downloadedFiles = <String, String>{};

      // Verify file existence - important for cleaning up stale entries
      for (var entry in allEntries.entries) {
        final file = File(entry.value);
        if (await file.exists()) {
          downloadedFiles[entry.key] = entry.value;
        } else {
          // If file doesn't exist, remove the entry from secure storage
          print("Stale entry found and removed for ID: ${entry.key}");
          await _secureStorage.delete(key: entry.key);
        }
      }

      return downloadedFiles;
    } catch (e) {
      print("Error retrieving all downloaded files: $e");
      return {};
    }
  }

   // You might want a way to clean up all downloads
   static Future<void> deleteAllFiles() async {
      final allEntries = await _secureStorage.readAll();
      for (var entry in allEntries.entries) {
         await deleteFile(entry.key); // Use the single delete logic
      }
   }
}