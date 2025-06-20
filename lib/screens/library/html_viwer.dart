import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mgw_tutorial/constants/color.dart';
import 'dart:io';

class HtmlViewer extends StatelessWidget {
  final String url;
  final String title;
  final bool isLocal;

  const HtmlViewer({
    super.key,
    required this.url,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isLocal
              ? FutureBuilder<String>(
                  future: File(url).readAsString(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Icon(
                          Icons.error,
                          size: 50,
                          color: AppColors.error,
                        ),
                      );
                    } else {
                      return HtmlWidget(
                        snapshot.data!,
                        textStyle: TextStyle(
                          color: isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                        ),
                      );
                    }
                  },
                )
              : HtmlWidget(
                  url,
                  textStyle: TextStyle(
                    color: isDarkMode ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
        ),
      ),
    );
  }
}