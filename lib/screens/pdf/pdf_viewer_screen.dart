// lib/screens/pdf/pdf_viewer_screen.dart
// ✅ CLEAN VERSION - Three-page side-by-side PDF viewer

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'dart:io';

class ThreePagePDFViewer extends StatefulWidget {
  final Uint8List pdfBytes;
  final String title;
  final VoidCallback? onEditPressed;

  const ThreePagePDFViewer({
    super.key,
    required this.pdfBytes,
    this.title = 'Consultation Report',
    this.onEditPressed,
  });

  @override
  State<ThreePagePDFViewer> createState() => _ThreePagePDFViewerState();
}

class _ThreePagePDFViewerState extends State<ThreePagePDFViewer> {
  int? _zoomedPageIndex;

  @override
  Widget build(BuildContext context) {
    // If a page is zoomed, show full-screen zoom view
    if (_zoomedPageIndex != null) {
      return _buildZoomedPage();
    }

    // Otherwise show three-page side-by-side view
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onEditPressed != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: widget.onEditPressed,
              tooltip: 'Edit Consultation',
            ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => _printPDF(context),
            tooltip: 'Print PDF',
          ),
        ],
      ),
      body: Row(
        children: [
          // Page 1: Patient Info
          Expanded(
            child: _buildPageColumn(
              pageIndex: 0,
              title: 'Page 1 - Patient Info',
              icon: Icons.person,
              color: Colors.blue,
            ),
          ),

          // Page 2: Diagrams & Visual Content
          Expanded(
            child: _buildPageColumn(
              pageIndex: 1,
              title: 'Page 2 - Visual Content',
              icon: Icons.image,
              color: Colors.purple,
            ),
          ),

          // Page 3: Clinical Summary
          Expanded(
            child: _buildPageColumn(
              pageIndex: 2,
              title: 'Page 3 - Clinical Summary',
              icon: Icons.description,
              color: Colors.green,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              'Tap any page to zoom in',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageColumn({
    required int pageIndex,
    required String title,
    required IconData icon,
    required MaterialColor color,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _zoomedPageIndex = pageIndex),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            // Page Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.shade50,
                border: Border(bottom: BorderSide(color: color.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: color.shade700),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // PDF Preview
            Expanded(
              child: PdfPreview(
                build: (format) => widget.pdfBytes,
                pages: [pageIndex],
                canChangeOrientation: false,
                canDebug: false,
                allowSharing: false,
                allowPrinting: false,
                scrollViewDecoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomedPage() {
    final pageTitles = [
      'Page 1 - Patient Info & Vitals',
      'Page 2 - Visual Content & Diagrams',
      'Page 3 - Clinical Summary & Treatment',
    ];

    final pageColors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(pageTitles[_zoomedPageIndex!]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _zoomedPageIndex = null),
        ),
        actions: [
          // Page indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pageColors[_zoomedPageIndex!].withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pageColors[_zoomedPageIndex!]),
            ),
            child: Text(
              'Page ${_zoomedPageIndex! + 1} of 3',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Container(
            color: Colors.white,
            child: PdfPreview(
              build: (format) => widget.pdfBytes,
              pages: [_zoomedPageIndex!],
              canChangeOrientation: false,
              canDebug: false,
              allowSharing: false,
              allowPrinting: false,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous Page
              ElevatedButton.icon(
                onPressed: _zoomedPageIndex! > 0
                    ? () => setState(() => _zoomedPageIndex = _zoomedPageIndex! - 1)
                    : null,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
              ),

              // Close Zoom
              OutlinedButton.icon(
                onPressed: () => setState(() => _zoomedPageIndex = null),
                icon: const Icon(Icons.view_column, size: 18),
                label: const Text('View All Pages'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),

              // Next Page
              ElevatedButton.icon(
                onPressed: _zoomedPageIndex! < 2
                    ? () => setState(() => _zoomedPageIndex = _zoomedPageIndex! + 1)
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _printPDF(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async => widget.pdfBytes,
        name: widget.title,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}