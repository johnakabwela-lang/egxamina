import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final String? imageTitle;
  final String? imageAttribution;
  final String block;
  final int? group;
  final int period;
  final int xpos;
  final int ypos;
  final String? appearance;
  final String? discoveredBy;
  final String? namedBy;
  final double? density;
  final double? molarHeat;
  final String? source;
  final String? spectralImg;
  final List<int>? shells;
  final String? electronConfiguration;
  final String? electronConfigurationSemantic;
  final double? electronAffinity;
  final double? electronegativityPauling;
  final List<double>? ionizationEnergies;
  final String? cpkHex;

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
    this.imageTitle,
    this.imageAttribution,
    required this.block,
    this.group,
    required this.period,
    required this.xpos,
    required this.ypos,
    this.appearance,
    this.discoveredBy,
    this.namedBy,
    this.density,
    this.molarHeat,
    this.source,
    this.spectralImg,
    this.shells,
    this.electronConfiguration,
    this.electronConfigurationSemantic,
    this.electronAffinity,
    this.electronegativityPauling,
    this.ionizationEnergies,
    this.cpkHex,
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
      imageTitle: json['image']?['title'],
      imageAttribution: json['image']?['attribution'],
      block: json['block'],
      group: json['group'],
      period: json['period'],
      xpos: json['xpos'],
      ypos: json['ypos'],
      appearance: json['appearance'],
      discoveredBy: json['discovered_by'],
      namedBy: json['named_by'],
      density: json['density']?.toDouble(),
      molarHeat: json['molar_heat']?.toDouble(),
      source: json['source'],
      spectralImg: json['spectral_img'],
      shells: json['shells']?.cast<int>(),
      electronConfiguration: json['electron_configuration'],
      electronConfigurationSemantic: json['electron_configuration_semantic'],
      electronAffinity: json['electron_affinity']?.toDouble(),
      electronegativityPauling: json['electronegativity_pauling']?.toDouble(),
      ionizationEnergies: json['ionization_energies']?.cast<double>(),
      cpkHex: json['cpk-hex'],
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

  // Get CPK color if available
  Color? get cpkColor {
    if (cpkHex != null) {
      return Color(int.parse('FF${cpkHex!}', radix: 16));
    }
    return null;
  }

  // Format electron shells display
  String get shellsDisplay {
    if (shells == null) return 'N/A';
    return shells!.join(', ');
  }

  // Format ionization energies display
  String get ionizationEnergiesDisplay {
    if (ionizationEnergies == null || ionizationEnergies!.isEmpty) return 'N/A';
    return ionizationEnergies!
            .take(3)
            .map((e) => e.toStringAsFixed(1))
            .join(', ') +
        (ionizationEnergies!.length > 3 ? '...' : '');
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

  const ElementCard({super.key, required this.element, required this.onTap});

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

// ================== IMAGE CARD WIDGET ==================
class ImageCard extends StatelessWidget {
  final Element element;

  const ImageCard({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    if (element.imageUrl == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.network(
                element.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          element.categoryColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (element.imageTitle != null)
                  Text(
                    element.imageTitle!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                if (element.imageAttribution != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    element.imageAttribution!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== ELEMENT DETAIL SCREEN ==================
class ElementDetailScreen extends StatelessWidget {
  final Element element;

  const ElementDetailScreen({super.key, required this.element});

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
            _buildMainElementCard(),
            const SizedBox(height: 24),

            // Image card
            ImageCard(element: element),
            const SizedBox(height: 16),

            // Basic Properties
            _buildPropertyCard('Basic Properties', [
              _PropertyItem('Phase', element.phase),
              _PropertyItem('Atomic Mass', '${element.atomicMass} u'),
              if (element.appearance != null)
                _PropertyItem('Appearance', element.appearance!),
              if (element.density != null)
                _PropertyItem('Density', '${element.density!} g/cm³'),
              _PropertyItem('Block', element.block.toUpperCase()),
              if (element.group != null)
                _PropertyItem('Group', element.group.toString()),
              _PropertyItem('Period', element.period.toString()),
            ]),

            const SizedBox(height: 16),

            // Thermal Properties
            if (element.melt != null ||
                element.boil != null ||
                element.molarHeat != null)
              _buildPropertyCard('Thermal Properties', [
                if (element.melt != null)
                  _PropertyItem(
                    'Melting Point',
                    '${element.melt!.toStringAsFixed(2)} K',
                  ),
                if (element.boil != null)
                  _PropertyItem(
                    'Boiling Point',
                    '${element.boil!.toStringAsFixed(2)} K',
                  ),
                if (element.molarHeat != null)
                  _PropertyItem(
                    'Molar Heat',
                    '${element.molarHeat!.toStringAsFixed(3)} J/(mol·K)',
                  ),
              ]),

            const SizedBox(height: 16),

            // Electronic Properties
            _buildPropertyCard('Electronic Properties', [
              if (element.electronConfiguration != null)
                _PropertyItem(
                  'Electron Configuration',
                  element.electronConfiguration!,
                ),
              if (element.shells != null)
                _PropertyItem('Electron Shells', element.shellsDisplay),
              if (element.electronAffinity != null)
                _PropertyItem(
                  'Electron Affinity',
                  '${element.electronAffinity!.toStringAsFixed(2)} kJ/mol',
                ),
              if (element.electronegativityPauling != null)
                _PropertyItem(
                  'Electronegativity',
                  element.electronegativityPauling!.toString(),
                ),
              if (element.ionizationEnergies != null)
                _PropertyItem(
                  'Ionization Energies',
                  '${element.ionizationEnergiesDisplay} kJ/mol',
                ),
            ]),

            const SizedBox(height: 16),

            // Discovery Information
            if (element.discoveredBy != null || element.namedBy != null)
              _buildPropertyCard('Discovery', [
                if (element.discoveredBy != null)
                  _PropertyItem('Discovered By', element.discoveredBy!),
                if (element.namedBy != null)
                  _PropertyItem('Named By', element.namedBy!),
              ]),

            const SizedBox(height: 16),

            // Summary section
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMainElementCard() {
    return Container(
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
              if (element.cpkColor != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: element.cpkColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: Colors.white,
                    size: 20,
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
    );
  }

  Widget _buildPropertyCard(String title, List<_PropertyItem> properties) {
    if (properties.isEmpty) return const SizedBox.shrink();

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
            ...properties.map(
              (prop) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        prop.label,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        prop.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
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

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
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
        if (element.spectralImg != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchUrl(element.spectralImg!),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('View Spectral Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _launchWikipedia() async {
    final url = 'https://en.wikipedia.org/wiki/${element.name}';
    _launchUrl(url);
  }

  void _launchUrl(String url) async {
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
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegend(context),
          ),
        ],
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
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

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _showLegend(BuildContext context) {
    final categories = elements
        .map((e) => e.category)
        .toSet()
        .map((category) => elements.firstWhere((e) => e.category == category))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Element Categories'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((element) {
              return ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  color: element.categoryColor,
                ),
                title: Text(element.category),
                dense: true,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
