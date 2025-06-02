import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:mgw_tutorial/constants/color.dart';

class PdfReaderScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfReaderScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  File? _pdfFile;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Delete existing file if retrying
      if (_pdfFile != null) {
        await _pdfFile!.delete();
        _pdfFile = null;
      }

      // Fetch PDF from URL
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        // Use path_provider's temporary directory
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.title.replaceAll(RegExp(r'[^\w\s]'), '')}.pdf');

        // Write PDF content to file
        await tempFile.writeAsBytes(response.bodyBytes);

        setState(() {
          _pdfFile = tempFile;
          _isLoading = false;
        });
      } else {
        throw HttpException('Failed to load PDF: ${response.statusCode}');
      }
    } catch (e) {
      String errorMsg;
      if (e is http.ClientException) {
        errorMsg = 'Network error: Please check your internet connection.';
      } else if (e is IOException) {
        errorMsg = 'File error: Unable to save the PDF.';
      } else {
        errorMsg = 'Error loading PDF: $e';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = errorMsg;
      });
    }
  }

  @override
  void dispose() async {
    // Clean up the temporary file asynchronously
    if (_pdfFile != null) {
      try {
        await _pdfFile!.delete();
      } catch (e) {
        debugPrint('Error deleting PDF file: $e');
      }
      _pdfFile = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
        actions: [
          if (_pdfFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Page $_currentPage/$_totalPages',
                  style: TextStyle(color: AppColors.onPrimaryLight),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(fontSize: 16, color: AppColors.onSurfaceLight),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.onPrimaryLight,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pdfFile != null) {
      return PDFView(
        filePath: _pdfFile!.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        onRender: (pages) {
          setState(() {
            _totalPages = pages ?? 0;
          });
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page! + 1; // flutter_pdfview uses 0-based index
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Failed to load PDF: $error';
          });
        },
      );
    }

    return Center(
      child: Text(
        'No PDF available',
        style: TextStyle(fontSize: 16, color: AppColors.onSurfaceLight),
      ),
    );
  }
}