// Enhanced Books Screen with Folder-Based PDF Support and Tools Panel
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ultsukulu/screens/calculator.dart';
import 'package:ultsukulu/screens/notepad.dart';
import 'package:ultsukulu/screens/periodic_table.dart';
import 'package:ultsukulu/screens/schedule_maker.dart';
import 'package:ultsukulu/screens/study_timer.dart';
import 'package:ultsukulu/screens/unit_converter.dart';
import 'package:ultsukulu/screens/wiki_browser.dart';
import 'package:ultsukulu/screens/dictionary_screen.dart';

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

      print('Looking for PDFs in subject: $subjectName');
      print('Subject folder: $subjectFolder');

      // Get list of PDFs for this subject from asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      print('Total assets in manifest: ${manifestMap.keys.length}');

      // Filter PDFs for current subject
      final pdfAssets = manifestMap.keys.where((key) {
        final isInSubjectFolder =
            key.startsWith('assets/pdfs/$subjectFolder/') ||
            key.startsWith('assets/$subjectFolder/') ||
            key.startsWith('assets/pdfs/');
        final isPdf = key.endsWith('.pdf');
        print(
          'Checking asset: $key - isInSubjectFolder: $isInSubjectFolder, isPdf: $isPdf',
        );
        return isInSubjectFolder && isPdf;
      }).toList();

      print('Found PDF assets: $pdfAssets');

      List<Map<String, String>> books = [];

      if (pdfAssets.isEmpty) {
        // If no assets found in subject-specific folder, check for any PDFs
        final allPdfs = manifestMap.keys
            .where((key) => key.endsWith('.pdf'))
            .toList();

        print('No subject-specific PDFs found. All PDFs in assets: $allPdfs');

        // Add any PDF that might match the subject
        for (String assetPath in allPdfs) {
          final fileName = assetPath.split('/').last;
          final pdfName = fileName
              .replaceAll('.pdf', '')
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '',
              )
              .join(' ');

          books.add({'name': pdfName, 'path': assetPath});
        }
      } else {
        for (String assetPath in pdfAssets) {
          final fileName = assetPath.split('/').last;
          final pdfName = fileName
              .replaceAll('.pdf', '')
              .replaceAll('_', ' ')
              .split(' ')
              .map(
                (word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '',
              )
              .join(' ');

          books.add({'name': pdfName, 'path': assetPath});
        }
      }

      print('Final books list: $books');

      setState(() {
        pdfBooks = books;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading PDFs: $e');
      // Fallback to predefined list if manifest reading fails
      _loadPredefinedPDFBooks();
    }
  }

  void _loadPredefinedPDFBooks() {
    print('Loading predefined PDF books as fallback');

    // Updated predefined PDF books to include your organic_chemistry.pdf
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
      ],
      'Chemistry': [
        {
          'name': 'Organic Chemistry',
          'path':
              'assets/pdfs/organic_chemistry.pdf', // This matches your actual file
        },
        {
          'name': 'Chemical Reactions',
          'path': 'assets/pdfs/chemistry/chemical_reactions.pdf',
        },
      ],
      'Biology': [
        {
          'name': 'Cell Biology',
          'path': 'assets/pdfs/biology/cell_biology.pdf',
        },
        {'name': 'Genetics', 'path': 'assets/pdfs/biology/genetics.pdf'},
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
      ],
    };

    final subjectName = widget.subject['name'] as String;

    print('Subject name: $subjectName');
    print('Available subjects: ${allPDFBooks.keys}');

    setState(() {
      pdfBooks = allPDFBooks[subjectName] ?? [];
      isLoading = false;
    });

    print('Loaded ${pdfBooks.length} predefined books for $subjectName');
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
      print('Attempting to load PDF asset: ${widget.pdfAssetPath}');

      if (kIsWeb) {
        // For web, we can't use local files, so we'll show an alternative message
        if (mounted) {
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
        return;
      }

      final byteData = await rootBundle.load(widget.pdfAssetPath);
      print(
        'Successfully loaded PDF asset, size: ${byteData.lengthInBytes} bytes',
      );

      final file = await _writeToFile(byteData);
      print('Successfully wrote PDF to local file: ${file.path}');

      if (mounted) {
        setState(() {
          localFilePath = file.path;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading PDF asset: $e');
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
        onTap: !kIsWeb && localFilePath != null && !hasError
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
            : kIsWeb
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'PDF viewing is not supported on web. Please use a mobile device or desktop app.',
                    ),
                    backgroundColor: Colors.orange,
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
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Web Not Supported',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

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
    if (kIsWeb) {
      return Center(
        child: Icon(Icons.web, color: Colors.orange[400], size: 32),
      );
    }

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

// Enhanced PDF Viewer Screen with integrated tools panel
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

class _PDFViewerScreenState extends State<PDFViewerScreen>
    with TickerProviderStateMixin {
  int currentPage = 0;
  int totalPages = 0;
  bool isToolsPanelOpen = false;
  Widget? currentToolWidget;
  String currentToolTitle = '';
  
  late AnimationController _panelAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<Offset> _panelSlideAnimation;
  late Animation<double> _panelOpacityAnimation;
  late Animation<double> _fabRotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _panelSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    ));

    _panelOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _toggleToolsPanel() {
    setState(() {
      isToolsPanelOpen = !isToolsPanelOpen;
    });

    if (isToolsPanelOpen) {
      _panelAnimationController.forward();
      _fabAnimationController.forward();
    } else {
      _panelAnimationController.reverse();
      _fabAnimationController.reverse();
      // Clear current tool when closing panel
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            currentToolWidget = null;
            currentToolTitle = '';
          });
        }
      });
    }
  }

  void _openTool(String title, Widget toolWidget) {
    setState(() {
      currentToolWidget = toolWidget;
      currentToolTitle = title;
    });
  }

  void _closeTool() {
    setState(() {
      currentToolWidget = null;
      currentToolTitle = '';
    });
  }

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
        actions: [
          if (currentToolWidget != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeTool,
              tooltip: 'Close $currentToolTitle',
            ),
        ],
      ),
      body: Stack(
        children: [
          // PDF Viewer
          PDFView(
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

          // Tools Panel Overlay
          if (isToolsPanelOpen)
            GestureDetector(
              onTap: currentToolWidget == null ? _toggleToolsPanel : null,
              child: AnimatedBuilder(
                animation: _panelOpacityAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withOpacity(0.3 * _panelOpacityAnimation.value),
                  );
                },
              ),
            ),

          // Current Tool Widget (Full Screen Overlay)
          if (currentToolWidget != null)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Tool Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.subjectColor.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: widget.subjectColor.withOpacity(0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.build,
                            color: widget.subjectColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentToolTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: widget.subjectColor,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: widget.subjectColor,
                            ),
                            onPressed: _closeTool,
                          ),
                        ],
                      ),
                    ),
                    // Tool Content
                    Expanded(child: currentToolWidget!),
                  ],
                ),
              ),
            ),

          // Tools Panel (Slide from right)
          AnimatedBuilder(
            animation: _panelSlideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _panelSlideAnimation,
                child: Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: AnimatedBuilder(
                    animation: _panelOpacityAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _panelOpacityAnimation.value,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(-5, 0),
                              ),
                            ],
                          ),
                          child: _buildToolsPanel(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabRotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _fabRotationAnimation.value * 2 * 3.14159,
            child: FloatingActionButton(
              onPressed: _toggleToolsPanel,
              backgroundColor: widget.subjectColor,
              child: Icon(
                isToolsPanelOpen ? Icons.close : Icons.build,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolsPanel() {
    if (!isToolsPanelOpen) return const SizedBox.shrink();

    return Column(
      children: [
        // Panel Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.subjectColor, widget.subjectColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.build,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Study Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Quick access utilities',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _toggleToolsPanel,
              ),
            ],
          ),
        ),

        // Tools List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildToolTile(
                'Calculator',
                Icons.calculate,
                const Color(0xFF1CB0F6),
                'Scientific calculator',
                () => _openTool('Calculator', const CalculatorScreen()),
              ),
              _buildToolTile(
                'Unit Converter',
                Icons.swap_horiz,
                const Color(0xFF58CC02),
                'Convert units easily',
                () => _openTool('Unit Converter', const UnitConverterScreen()),
              ),
              _buildToolTile(
                'Dictionary',
                Icons.menu_book,
                const Color(0xFFFF4B4B),
                'Look up definitions',
                () => _openTool('Dictionary', const DictionaryScreen()),
              ),
              _buildToolTile(
                'Periodic Table',
                Icons.science,
                const Color(0xFFFF9600),
                'Chemical elements',
                () => _openTool('Periodic Table', const PeriodicTableScreen()),
              ),
              _buildToolTile(
                'Wiki Browser',
                Icons.public,
                const Color(0xFF7B68EE),
                'Research topics',
                () => _openTool('Wiki Browser', const WikipediaExplorerScreen()),
              ),
              _buildToolTile(
                'Notepad',
                Icons.note_add,
                const Color(0xFF32CD32),
                'Take notes',
                () => _openTool('Notepad', const NotepadScreen()),
              ),
              _buildToolTile(
                'Schedule Maker',
                Icons.schedule,
                const Color(0xFFDA70D6),
                'Plan your time',
                () => _openTool('Schedule Maker', const ScheduleMakerScreen()),
              ),
              _buildToolTile(
                'Study Timer',
                Icons.timer,
                const Color(0xFF20B2AA),
                'Focus sessions',
                () => _openTool('Study Timer', const StudyTimerScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolTile(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
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
