// Enhanced Books Screen with Folder-Based PDF Support
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class SubjectBooksScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectBooksScreen({super.key, required this.subject});

  @override
  State<SubjectBooksScreen> createState() => _SubjectBooksScreenState();
}

class _SubjectBooksScreenState extends State<SubjectBooksScreen> {
  List<Map<String, String>> pdfBooks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPDFBooks();
  }

  Future<void> _loadPDFBooks() async {
    try {
      final subjectName = widget.subject['name'] as String;
      final subjectFolder = subjectName.toLowerCase().replaceAll(' ', '_');

      // Get list of PDFs for this subject from asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = Map<String, dynamic>.from(
        const StandardMessageCodec().decodeMessage(
          Uint8List.fromList(manifestContent.codeUnits) as ByteData?,
        ),
      );

      // Filter PDFs for current subject
      final pdfAssets = manifestMap.keys
          .where(
            (key) =>
                key.startsWith('assets/pdfs/$subjectFolder/') &&
                key.endsWith('.pdf'),
          )
          .toList();

      List<Map<String, String>> books = [];
      for (String assetPath in pdfAssets) {
        final fileName = assetPath.split('/').last;
        final pdfName = fileName
            .replaceAll('.pdf', '')
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');

        books.add({'name': pdfName, 'path': assetPath});
      }

      setState(() {
        pdfBooks = books;
        isLoading = false;
      });
    } catch (e) {
      // Fallback to predefined list if manifest reading fails
      _loadPredefinedPDFBooks();
    }
  }

  void _loadPredefinedPDFBooks() {
    // Fallback predefined PDF books for each subject
    final allPDFBooks = {
      'Mathematics': [
        {
          'name': 'Advanced Calculus',
          'path': 'assets/pdfs/mathematics/advanced_calculus.pdf',
        },
        {
          'name': 'Linear Algebra',
          'path': 'assets/pdfs/mathematics/linear_algebra.pdf',
        },
        {
          'name': 'Statistics Guide',
          'path': 'assets/pdfs/mathematics/statistics_guide.pdf',
        },
        {
          'name': 'Differential Equations',
          'path': 'assets/pdfs/mathematics/differential_equations.pdf',
        },
      ],
      'Physics': [
        {
          'name': 'Quantum Mechanics',
          'path': 'assets/pdfs/physics/quantum_mechanics.pdf',
        },
        {
          'name': 'Classical Physics',
          'path': 'assets/pdfs/physics/classical_physics.pdf',
        },
        {
          'name': 'Thermodynamics',
          'path': 'assets/pdfs/physics/thermodynamics.pdf',
        },
        {
          'name': 'Electromagnetism',
          'path': 'assets/pdfs/physics/electromagnetism.pdf',
        },
      ],
      'Chemistry': [
        {
          'name': 'Organic Chemistry',
          'path': 'assets/pdfs/chemistry/organic_chemistry.pdf',
        },
        {
          'name': 'Chemical Reactions',
          'path': 'assets/pdfs/chemistry/chemical_reactions.pdf',
        },
        {
          'name': 'Periodic Table Guide',
          'path': 'assets/pdfs/chemistry/periodic_table.pdf',
        },
        {
          'name': 'Analytical Chemistry',
          'path': 'assets/pdfs/chemistry/analytical_chemistry.pdf',
        },
      ],
      'Biology': [
        {
          'name': 'Cell Biology',
          'path': 'assets/pdfs/biology/cell_biology.pdf',
        },
        {'name': 'Genetics', 'path': 'assets/pdfs/biology/genetics.pdf'},
        {'name': 'Ecology', 'path': 'assets/pdfs/biology/ecology.pdf'},
        {
          'name': 'Human Anatomy',
          'path': 'assets/pdfs/biology/human_anatomy.pdf',
        },
      ],
      'Computer Science': [
        {
          'name': 'Data Structures',
          'path': 'assets/pdfs/computer_science/data_structures.pdf',
        },
        {
          'name': 'Algorithms',
          'path': 'assets/pdfs/computer_science/algorithms.pdf',
        },
        {
          'name': 'Database Systems',
          'path': 'assets/pdfs/computer_science/database_systems.pdf',
        },
      ],
    };

    final subjectName = widget.subject['name'] as String;
    setState(() {
      pdfBooks = allPDFBooks[subjectName] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('${widget.subject['name']} Books'),
        backgroundColor: widget.subject['color'] as Color,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pdfBooks.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pdfBooks.length,
              itemBuilder: (context, index) {
                final pdfBook = pdfBooks[index];
                return PDFBookCard(
                  pdfName: pdfBook['name']!,
                  pdfAssetPath: pdfBook['path']!,
                  subject: widget.subject,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No PDF books available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PDF books for ${widget.subject['name']} will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PDFBookCard extends StatefulWidget {
  final String pdfName;
  final String pdfAssetPath;
  final Map<String, dynamic> subject;

  const PDFBookCard({
    super.key,
    required this.pdfName,
    required this.pdfAssetPath,
    required this.subject,
  });

  @override
  State<PDFBookCard> createState() => _PDFBookCardState();
}

class _PDFBookCardState extends State<PDFBookCard> {
  String? localFilePath;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _copyAssetToLocal();
  }

  Future<void> _copyAssetToLocal() async {
    try {
      final byteData = await rootBundle.load(widget.pdfAssetPath);
      final file = await _writeToFile(byteData);
      if (mounted) {
        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<File> _writeToFile(ByteData data) async {
    final buffer = data.buffer;
    final directory = await getTemporaryDirectory();
    final fileName = widget.pdfName.replaceAll(' ', '_').toLowerCase();
    return await File(
      '${directory.path}/$fileName.pdf',
    ).writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: localFilePath != null && !hasError
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerScreen(
                      pdfPath: localFilePath!,
                      title: widget.pdfName,
                      subjectColor: widget.subject['color'] as Color,
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // PDF Preview Container
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildPreview(),
                ),
              ),
              const SizedBox(width: 16),
              // PDF Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pdfName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 16,
                          color: Colors.red[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PDF Document',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusChip(),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Loading...',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    if (hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Error Loading',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Available',
        style: TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (hasError || localFilePath == null) {
      return Center(
        child: Icon(Icons.error_outline, color: Colors.red[400], size: 32),
      );
    }

    return PDFView(
      filePath: localFilePath!,
      enableSwipe: false,
      swipeHorizontal: false,
      autoSpacing: false,
      pageSnap: false,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: true,
      onRender: (pages) {
        // PDF rendered successfully
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            hasError = true;
          });
        }
      },
      onPageError: (page, error) {
        if (mounted) {
          setState(() {
            hasError = true;
          });
        }
      },
    );
  }
}

// PDF Viewer Screen
class PDFViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;
  final Color subjectColor;

  const PDFViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
    required this.subjectColor,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  int currentPage = 0;
  int totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 18)),
            if (totalPages > 0)
              Text(
                'Page ${currentPage + 1} of $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: widget.subjectColor,
        foregroundColor: Colors.white,
      ),
      body: PDFView(
        filePath: widget.pdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.BOTH,
        onRender: (pages) {
          setState(() {
            totalPages = pages ?? 0;
          });
        },
        onError: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading PDF: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        onPageChanged: (page, total) {
          setState(() {
            currentPage = page ?? 0;
            totalPages = total ?? 0;
          });
        },
      ),
    );
  }
}

// Updated Notes Screen (keeping original functionality)
class SubjectNotesScreen extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectNotesScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('${subject['name']} Notes'),
        backgroundColor: subject['color'] as Color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: subject['color'] as Color),
            const SizedBox(height: 16),
            Text(
              '${subject['name']} Notes',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Study notes and summaries will be available here'),
          ],
        ),
      ),
    );
  }
}
