import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mgw_tutorial/constants/color.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final bool isLocal;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.isLocal,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dynamicAppBarBackground = isDarkMode ? AppColors.appBarBackgroundDark : AppColors.appBarBackgroundLight;
    final dynamicScaffoldBackground = isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: dynamicScaffoldBackground,
      appBar: AppBar(
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        backgroundColor: dynamicAppBarBackground,
        titleSpacing: 0,
      ),
      body: Center(
        child: isLocal
            ? Image.file(
                File(imageUrl),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  size: 50,
                  color: AppColors.error,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.error,
                  size: 50,
                  color: AppColors.error,
                ),
              ),
      ),
    );
  }
}