import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';

class WikipediaExplorerScreen extends StatefulWidget {
  const WikipediaExplorerScreen({super.key});

  @override
  State<WikipediaExplorerScreen> createState() =>
      _WikipediaExplorerScreenState();
}

class _WikipediaExplorerScreenState extends State<WikipediaExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<WikipediaSearchResult> _searchResults = [];
  WikipediaArticle? _currentArticle;
  bool _isSearching = false;
  bool _isLoadingArticle = false;
  String _currentView = 'search'; // 'search' or 'article'

  @override
  void initState() {
    super.initState();
    _loadFeaturedArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get appropriate headers based on platform
  Map<String, String> get _headers {
    final headers = <String, String>{
      'User-Agent': 'WikipediaExplorer/1.0 (Flutter App)',
    };

    // For web, we need to handle CORS differently
    if (kIsWeb) {
      headers['Accept'] = 'application/json';
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  // Get base URL based on platform (handle CORS for web)
  String get _baseUrl {
    if (kIsWeb) {
      // Use CORS proxy for web or Wikipedia's CORS-enabled endpoints
      return 'https://en.wikipedia.org/api/rest_v1';
    } else {
      return 'https://en.wikipedia.org/api/rest_v1';
    }
  }

  Future<void> _searchWikipedia(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final searchUrl =
          '$_baseUrl/page/search?q=${Uri.encodeComponent(query)}&limit=20';

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pages = data['pages'] ?? [];

        setState(() {
          _searchResults = pages
              .map((page) => WikipediaSearchResult(
                    title: page['title'] ?? '',
                    description: page['description'] ?? '',
                    excerpt: page['extract'] ?? '',
                    key: page['key'] ?? '',
                    thumbnail: page['thumbnail']?['source'],
                    pageid: page['id']?.toString(),
                  ))
              .toList();
        });
      } else {
        // Fallback to OpenSearch API if REST API fails (better CORS support)
        await _searchWikipediaFallback(query);
      }
    } catch (e) {
      // Try fallback method for web compatibility
      if (kIsWeb) {
        await _searchWikipediaFallback(query);
      } else {
        _showError('Error searching Wikipedia: $e');
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Fallback search method with better CORS support
  Future<void> _searchWikipediaFallback(String query) async {
    try {
      final fallbackUrl = 'https://en.wikipedia.org/w/api.php'
          '?action=opensearch'
          '&search=${Uri.encodeComponent(query)}'
          '&limit=20'
          '&namespace=0'
          '&format=json'
          '&origin=*'; // Important for CORS

      final response = await http.get(
        Uri.parse(fallbackUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.length >= 4) {
          final List<String> titles = List<String>.from(data[1]);
          final List<String> descriptions = List<String>.from(data[2]);
          final List<String> urls = List<String>.from(data[3]);

          setState(() {
            _searchResults = List.generate(titles.length, (index) {
              return WikipediaSearchResult(
                title: titles[index],
                description: descriptions[index],
                excerpt: descriptions[index],
                key: titles[index].replaceAll(' ', '_'),
                thumbnail: null,
                url: urls[index],
              );
            });
          });
        }
      }
    } catch (e) {
      _showError('Error searching Wikipedia: $e');
    }
  }

  Future<void> _loadArticle(String title) async {
    setState(() {
      _isLoadingArticle = true;
    });

    try {
      // Try REST API first
      final summaryUrl = '$_baseUrl/page/summary/${Uri.encodeComponent(title)}';

      final response = await http.get(
        Uri.parse(summaryUrl),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _currentArticle = WikipediaArticle(
            title: data['title'] ?? title,
            extract: data['extract'] ?? '',
            thumbnail: data['thumbnail']?['source'],
            url: data['content_urls']?['desktop']?['page'],
            lastModified: data['timestamp'],
          );
          _currentView = 'article';
        });
      } else {
        // Fallback to extract API
        await _loadArticleFallback(title);
      }
    } catch (e) {
      if (kIsWeb) {
        await _loadArticleFallback(title);
      } else {
        _showError('Error loading article: $e');
      }
    } finally {
      setState(() {
        _isLoadingArticle = false;
      });
    }
  }

  // Fallback article loading with better CORS support
  Future<void> _loadArticleFallback(String title) async {
    try {
      final fallbackUrl = 'https://en.wikipedia.org/w/api.php'
          '?action=query'
          '&format=json'
          '&titles=${Uri.encodeComponent(title)}'
          '&prop=extracts|pageimages'
          '&exintro=true'
          '&explaintext=true'
          '&exsectionformat=plain'
          '&piprop=original'
          '&origin=*'; // Important for CORS

      final response = await http.get(
        Uri.parse(fallbackUrl),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;

        if (pages != null && pages.isNotEmpty) {
          final pageData = pages.values.first;
          final extract = pageData['extract'] ?? '';
          final thumbnail = pageData['original']?['source'];

          setState(() {
            _currentArticle = WikipediaArticle(
              title: pageData['title'] ?? title,
              extract: extract.isNotEmpty ? extract : 'Content not available.',
              thumbnail: thumbnail,
              url:
                  'https://en.wikipedia.org/wiki/${Uri.encodeComponent(title)}',
              lastModified: null,
            );
            _currentView = 'article';
          });
        }
      }
    } catch (e) {
      _showError('Error loading article: $e');
    }
  }

  Future<void> _loadFeaturedArticles() async {
    // Load some popular articles as default content
    const popularTopics = [
      'Zambia',
      'Climate Change',
      'Space Exploration',
      'Renewable Energy',
      'Quantum Computing',
      'The heart'
    ];

    // Pick a random topic to show variety
    final randomTopic =
        popularTopics[DateTime.now().millisecond % popularTopics.length];
    await _searchWikipedia(randomTopic);
  }

  Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      } else {
        _showError('Could not open URL');
      }
    } catch (e) {
      _showError('Error opening browser: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[600],
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  String get _platformName {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform not available
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B68EE),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentView == 'search' ? 'Wikipedia Explorer' : 'Article'),
            if (kDebugMode)
              Text(
                _platformName,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        elevation: 0,
        leading: _currentView == 'article'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentView = 'search';
                    _currentArticle = null;
                  });
                },
              )
            : null,
        actions: [
          if (_currentView == 'search')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadFeaturedArticles(),
              tooltip: 'Load featured articles',
            ),
        ],
      ),
      body: _currentView == 'search' ? _buildSearchView() : _buildArticleView(),
    );
  }

  Widget _buildSearchView() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF7B68EE),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search Wikipedia...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _searchWikipedia,
                onChanged: (value) {
                  setState(() {}); // Update UI to show/hide clear button
                },
              ),
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Running on web - some features may be limited',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Search Results
        Expanded(
          child: _isSearching
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF7B68EE)),
                      SizedBox(height: 16),
                      Text('Searching Wikipedia...'),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? _buildEmptyState()
                  : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.public,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Explore Wikipedia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for any topic to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () => _searchWikipedia('Science'),
                icon: const Icon(Icons.science),
                label: const Text('Science'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _searchWikipedia('Technology'),
                icon: const Icon(Icons.computer),
                label: const Text('Technology'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _searchWikipedia('History'),
                icon: const Icon(Icons.history_edu),
                label: const Text('History'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: result.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      result.thumbnail!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B68EE).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B68EE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.article, color: Color(0xFF7B68EE)),
                      ),
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B68EE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.article, color: Color(0xFF7B68EE)),
                  ),
            title: Text(
              result.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      result.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (result.excerpt.isNotEmpty &&
                    result.excerpt != result.description)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      result.excerpt.length > 100
                          ? '${result.excerpt.substring(0, 100)}...'
                          : result.excerpt,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => _loadArticle(result.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }

  Widget _buildArticleView() {
    if (_isLoadingArticle) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF7B68EE)),
            SizedBox(height: 16),
            Text('Loading article...'),
          ],
        ),
      );
    }

    if (_currentArticle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Article not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentView = 'search';
                });
              },
              child: const Text('Back to Search'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article Header
          if (_currentArticle!.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _currentArticle!.thumbnail!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B68EE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B68EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child:
                        Icon(Icons.image, size: 64, color: Color(0xFF7B68EE)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Article Title
          Text(
            _currentArticle!.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),

          const SizedBox(height: 16),

          // Article Content
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _currentArticle!.extract.isEmpty
                    ? 'Content not available for this article.'
                    : _currentArticle!.extract,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Color(0xFF404040),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _currentArticle!.url != null
                    ? () => _openInBrowser(_currentArticle!.url!)
                    : null,
                icon: const Icon(Icons.open_in_browser),
                label:
                    const Text(kIsWeb ? 'Open in New Tab' : 'Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B68EE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentView = 'search';
                    _currentArticle = null;
                  });
                },
                icon: const Icon(Icons.search),
                label: const Text('Back to Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7B68EE),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WikipediaSearchResult {
  final String title;
  final String description;
  final String excerpt;
  final String key;
  final String? thumbnail;
  final String? pageid;
  final String? url;

  WikipediaSearchResult({
    required this.title,
    required this.description,
    required this.excerpt,
    required this.key,
    this.thumbnail,
    this.pageid,
    this.url,
  });
}

class WikipediaArticle {
  final String title;
  final String extract;
  final String? thumbnail;
  final String? url;
  final String? lastModified;

  WikipediaArticle({
    required this.title,
    required this.extract,
    this.thumbnail,
    this.url,
    this.lastModified,
  });
}
