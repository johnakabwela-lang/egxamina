import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultsukulu/screens/calculator.dart';
import 'package:ultsukulu/screens/notepad.dart';
import 'package:ultsukulu/screens/schedule_maker.dart';
import 'package:ultsukulu/screens/study_timer.dart';
import 'package:ultsukulu/screens/unit_converter.dart';
import 'package:ultsukulu/screens/wiki_browser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// Main Tools Screen with enhanced press effects and animations
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Student Tools',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced header section with subtle animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF58CC02), Color(0xFF46A302)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF58CC02).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Study Toolkit',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essential tools for your studies',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Tools grid with staggered animation
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildAnimatedToolCard(
                  context,
                  'Unit Converter',
                  Icons.swap_horiz,
                  const Color(0xFF58CC02),
                  'Convert units easily',
                  0,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnitConverterScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Calculator',
                  Icons.calculate,
                  const Color(0xFF1CB0F6),
                  'Scientific calculator',
                  1,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalculatorScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Dictionary',
                  Icons.menu_book,
                  const Color(0xFFFF4B4B),
                  'Look up definitions',
                  2,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DictionaryScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Periodic Table',
                  Icons.science,
                  const Color(0xFFFF9600),
                  'Chemical elements',
                  3,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PeriodicTableScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Wiki Browser',
                  Icons.public,
                  const Color(0xFF7B68EE),
                  'Research topics',
                  4,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WikipediaExplorerScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Notepad',
                  Icons.note_add,
                  const Color(0xFF32CD32),
                  'Take notes',
                  5,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotepadScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Schedule Maker',
                  Icons.schedule,
                  const Color(0xFFDA70D6),
                  'Plan your time',
                  6,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ScheduleMakerScreen(),
                    ),
                  ),
                ),
                _buildAnimatedToolCard(
                  context,
                  'Study Timer',
                  Icons.timer,
                  const Color(0xFF20B2AA),
                  'Focus sessions',
                  7,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudyTimerScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Enhanced quick access section
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFF9600,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  color: Color(0xFFFF9600),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Quick Access',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildQuickAccessButton(
                                Icons.calculate,
                                'Calculator',
                                const Color(0xFF1CB0F6),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CalculatorScreen(),
                                  ),
                                ),
                              ),
                              _buildQuickAccessButton(
                                Icons.menu_book,
                                'Dictionary',
                                const Color(0xFFFF4B4B),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DictionaryScreen(),
                                  ),
                                ),
                              ),
                              _buildQuickAccessButton(
                                Icons.note_add,
                                'Notes',
                                const Color(0xFF32CD32),
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotepadScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced tool card with Duolingo-style press effect and staggered animation
  Widget _buildAnimatedToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    int index,
    VoidCallback onTap,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _buildToolCard(context, title, icon, color, subtitle, onTap),
          ),
        );
      },
    );
  }

  // Tool card with enhanced press effect
  Widget _buildToolCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return DuolingoStyleCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 34, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced quick access button with press effect
  Widget _buildQuickAccessButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return DuolingoStyleCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Duolingo-style pressable card widget
class DuolingoStyleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration animationDuration;

  const DuolingoStyleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<DuolingoStyleCard> createState() => _DuolingoStyleCardState();
}

class _DuolingoStyleCardState extends State<DuolingoStyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              transform: Matrix4.identity()
                ..translate(0.0, 3.0 * _animationController.value),
              child: Opacity(
                opacity: 0.85 + (0.15 * (1 - _animationController.value)),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4B4B),
        foregroundColor: Colors.white,
        title: const Text('Dictionary'),
        elevation: 0,
      ),
      body: _buildDummyContent(
        'English Dictionary',
        Icons.menu_book,
        const Color(0xFFFF4B4B),
        'Look up word definitions, synonyms, and pronunciation',
        [
          'Word definitions and meanings',
          'Synonyms and antonyms',
          'Pronunciation guides',
          'Word etymology and history',
        ],
      ),
    );
  }
}


class Element {
  final String name;
  final String symbol;
  final int number;
  final String category;
  final double atomicMass;
  final double? boil;
  final double? melt;
  final String phase;
  final String summary;
  final String? imageUrl;
  final String block;
  final int? group;
  final int period;
  final int xpos;
  final int ypos;

  Element({
    required this.name,
    required this.symbol,
    required this.number,
    required this.category,
    required this.atomicMass,
    this.boil,
    this.melt,
    required this.phase,
    required this.summary,
    this.imageUrl,
    required this.block,
    this.group,
    required this.period,
    required this.xpos,
    required this.ypos,
  });

  factory Element.fromJson(Map<String, dynamic> json) {
    return Element(
      name: json['name'],
      symbol: json['symbol'],
      number: json['number'],
      category: json['category'],
      atomicMass: json['atomic_mass'].toDouble(),
      boil: json['boil']?.toDouble(),
      melt: json['melt']?.toDouble(),
      phase: json['phase'],
      summary: json['summary'],
      imageUrl: json['image']?['url'],
      block: json['block'],
      group: json['group'],
      period: json['period'],
      xpos: json['xpos'],
      ypos: json['ypos'],
    );
  }

  // Color coding by category
  Color get categoryColor {
    switch (category.toLowerCase()) {
      case 'diatomic nonmetal':
        return const Color(0xFF4CAF50);
      case 'noble gas':
        return const Color(0xFF9C27B0);
      case 'alkali metal':
        return const Color(0xFFF44336);
      case 'alkaline earth metal':
        return const Color(0xFFFF9800);
      case 'metalloid':
        return const Color(0xFF607D8B);
      case 'polyatomic nonmetal':
        return const Color(0xFF2196F3);
      case 'post-transition metal':
        return const Color(0xFF795548);
      case 'transition metal':
        return const Color(0xFF00BCD4);
      case 'lanthanide':
        return const Color(0xFFE91E63);
      case 'actinide':
        return const Color(0xFF673AB7);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}

// ================== SERVICE ==================
class PeriodicTableService {
  static Future<List<Element>> loadElements() async {
    try {
      final String data = await rootBundle.loadString('assets/periodic.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      final List<dynamic> elementsJson = jsonData['elements'];
      
      return elementsJson.map((json) => Element.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load periodic table data: $e');
    }
  }
}

// ================== ELEMENT CARD WIDGET ==================
class ElementCard extends StatelessWidget {
  final Element element;
  final VoidCallback onTap;

  const ElementCard({
    Key? key,
    required this.element,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: element.categoryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Atomic number (top-left)
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                element.number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Element symbol (center)
            Center(
              child: Text(
                element.symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== PROPERTY ITEM HELPER CLASS ==================
class _PropertyItem {
  final String label;
  final String value;
  
  _PropertyItem(this.label, this.value);
}

// ================== ELEMENT DETAIL SCREEN ==================
class ElementDetailScreen extends StatelessWidget {
  final Element element;

  const ElementDetailScreen({Key? key, required this.element}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: element.categoryColor,
        foregroundColor: Colors.white,
        title: Text(element.name),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main element display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: element.categoryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        element.number.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (element.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            element.imageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.science,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    element.symbol,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    element.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    element.category.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Properties section
            _buildPropertyCard('Properties', [
              _PropertyItem('Phase', element.phase),
              _PropertyItem('Atomic Mass', '${element.atomicMass} u'),
              if (element.melt != null)
                _PropertyItem('Melting Point', '${element.melt!.toStringAsFixed(2)} K'),
              if (element.boil != null)
                _PropertyItem('Boiling Point', '${element.boil!.toStringAsFixed(2)} K'),
              _PropertyItem('Block', element.block.toUpperCase()),
              if (element.group != null)
                _PropertyItem('Group', element.group.toString()),
              _PropertyItem('Period', element.period.toString()),
            ]),
            
            const SizedBox(height: 16),
            
            // Summary section
            _buildSummaryCard(),
            
            const SizedBox(height: 24),
            
            // More info button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchWikipedia,
                icon: const Icon(Icons.open_in_new),
                label: const Text('More Info on Wikipedia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: element.categoryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(String title, List<_PropertyItem> properties) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            ...properties.map((prop) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prop.label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                  Text(
                    prop.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              element.summary,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWikipedia() async {
    final url = 'https://en.wikipedia.org/wiki/${element.name}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

// ================== PERIODIC TABLE SCREEN ==================
class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> 
    with SingleTickerProviderStateMixin {
  List<Element> elements = [];
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadElements();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadElements() async {
    try {
      final loadedElements = await PeriodicTableService.loadElements();
      setState(() {
        elements = loadedElements;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9600),
        foregroundColor: Colors.white,
        title: const Text('Periodic Table'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9600)),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load periodic table',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadElements();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildPeriodicTable(),
    );
  }

  Widget _buildPeriodicTable() {
    // Calculate grid dimensions
    final maxX = elements.map((e) => e.xpos).reduce((a, b) => a > b ? a : b);
    final maxY = elements.map((e) => e.ypos).reduce((a, b) => a > b ? a : b);

    // Create a 2D grid
    final grid = List.generate(
      maxY,
      (_) => List.generate(maxX, (_) => null as Element?),
    );

    // Fill the grid with elements
    for (final element in elements) {
      if (element.ypos > 0 && element.xpos > 0) {
        grid[element.ypos - 1][element.xpos - 1] = element;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: grid.asMap().entries.map((rowEntry) {
              return Row(
                children: rowEntry.value.asMap().entries.map((colEntry) {
                  final element = colEntry.value;
                  return Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.all(1),
                    child: element != null
                        ? ElementCard(
                            element: element,
                            onTap: () => _navigateToDetail(element),
                          )
                        : const SizedBox(),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(Element element) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ElementDetailScreen(element: element),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
// Shared dummy content builder
Widget _buildDummyContent(
  String title,
  IconData icon,
  Color color,
  String description,
  List<String> features,
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, size: 45, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Features',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: color, size: 16),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.construction, size: 40, color: color),
              ),
              const SizedBox(height: 20),
              const Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This tool is currently under development. Check back soon for the full functionality!',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
