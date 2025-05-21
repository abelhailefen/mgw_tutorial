//lib/screens/library/library_screen.dart
import 'package:flutter/material.dart';
import 'package:mgw_tutorial/screens/library/library_content_view.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0), // Keep padding if desired, or remove if LibraryContentView handles it
      child: LibraryContentView(),
    );
  }
}