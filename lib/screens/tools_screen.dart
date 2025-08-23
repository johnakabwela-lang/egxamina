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
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;


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

// Data Models
class WordDefinition {
  final String word;
  final String phonetic;
  final List<String> audioUrls;
  final List<Meaning> meanings;
  final String? origin;

  WordDefinition({
    required this.word,
    required this.phonetic,
    required this.audioUrls,
    required this.meanings,
    this.origin,
  });

  factory WordDefinition.fromJson(Map<String, dynamic> json) {
    List<String> audioUrls = [];
    if (json['phonetics'] != null) {
      for (var phonetic in json['phonetics']) {
        if (phonetic['audio'] != null && phonetic['audio'].toString().isNotEmpty) {
          audioUrls.add(phonetic['audio']);
        }
      }
    }

    List<Meaning> meanings = [];
    if (json['meanings'] != null) {
      for (var meaning in json['meanings']) {
        meanings.add(Meaning.fromJson(meaning));
      }
    }

    return WordDefinition(
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? '',
      audioUrls: audioUrls,
      meanings: meanings,
      origin: json['origin'],
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.antonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    List<Definition> definitions = [];
    if (json['definitions'] != null) {
      for (var def in json['definitions']) {
        definitions.add(Definition.fromJson(def));
      }
    }

    return Meaning(
      partOfSpeech: json['partOfSpeech'] ?? '',
      definitions: definitions,
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class Definition {
  final String definition;
  final String? example;

  Definition({
    required this.definition,
    this.example,
  });

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'] ?? '',
      example: json['example'],
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String word;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.word,
  });
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  WordDefinition? _currentWord;
  bool _isLoading = false;
  String? _error;
  
  // Quiz state
  QuizQuestion? _currentQuestion;
  bool _quizMode = false;
  int? _selectedAnswer;
  bool _showAnswer = false;
  int _score = 0;
  int _totalQuestions = 0;
  bool _isGeneratingQuestion = false;

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _searchWord(String word) async {
    if (word.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _currentWord = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/${word.trim()}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _currentWord = WordDefinition.fromJson(data[0]);
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Word not found. Please try another word.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch word definition. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to play audio')),
      );
    }
  }

  Future<void> _generateQuizQuestion() async {
    setState(() {
      _isGeneratingQuestion = true;
    });

    try {
      // Get random word
      final randomResponse = await http.get(
        Uri.parse('https://random-word-api.vercel.app/api?words=1'),
      );

      if (randomResponse.statusCode == 200) {
        final List<dynamic> randomData = json.decode(randomResponse.body);
        final randomWord = randomData[0];

        // Get definition for random word
        final defResponse = await http.get(
          Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$randomWord'),
        );

        if (defResponse.statusCode == 200) {
          final List<dynamic> defData = json.decode(defResponse.body);
          final wordDef = WordDefinition.fromJson(defData[0]);

          // Generate question
          final question = await _createQuestion(wordDef);
          
          setState(() {
            _currentQuestion = question;
            _selectedAnswer = null;
            _showAnswer = false;
            _isGeneratingQuestion = false;
          });
        } else {
          // Fallback to a different question type if API fails
          _generateQuizQuestion();
        }
      }
    } catch (e) {
      setState(() {
        _isGeneratingQuestion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate quiz question')),
      );
    }
  }

  Future<QuizQuestion> _createQuestion(WordDefinition word) async {
    final random = Random();
    final questionTypes = ['definition', 'synonym', 'antonym'];
    
    // Filter available question types based on available data
    List<String> availableTypes = ['definition'];
    
    bool hasSynonyms = word.meanings.any((m) => m.synonyms.isNotEmpty);
    bool hasAntonyms = word.meanings.any((m) => m.antonyms.isNotEmpty);
    
    if (hasSynonyms) availableTypes.add('synonym');
    if (hasAntonyms) availableTypes.add('antonym');
    
    final questionType = availableTypes[random.nextInt(availableTypes.length)];
    
    switch (questionType) {
      case 'definition':
        return _createDefinitionQuestion(word);
      case 'synonym':
        return _createSynonymQuestion(word);
      case 'antonym':
        return _createAntonymQuestion(word);
      default:
        return _createDefinitionQuestion(word);
    }
  }

  QuizQuestion _createDefinitionQuestion(WordDefinition word) {
    final random = Random();
    final definition = word.meanings[0].definitions[0].definition;
    
    // Generate wrong answers
    List<String> wrongAnswers = [
      'A type of ancient building structure',
      'A mathematical calculation method',
      'A cooking technique from France',
    ];
    
    List<String> options = [word.word, ...wrongAnswers];
    options.shuffle();
    
    final correctIndex = options.indexOf(word.word);
    
    return QuizQuestion(
      question: 'What does this definition describe?\n\n"$definition"',
      options: options,
      correctIndex: correctIndex,
      word: word.word,
    );
  }

  QuizQuestion _createSynonymQuestion(WordDefinition word) {
    final random = Random();
    final synonyms = word.meanings
        .expand((m) => m.synonyms)
        .where((s) => s.isNotEmpty)
        .toList();
    
    final correctSynonym = synonyms[random.nextInt(synonyms.length)];
    
    List<String> wrongAnswers = [
      'completely',
      'hardly',
      'never',
    ];
    
    List<String> options = [correctSynonym, ...wrongAnswers];
    options.shuffle();
    
    final correctIndex = options.indexOf(correctSynonym);
    
    return QuizQuestion(
      question: 'Which word is a synonym of "${word.word}"?',
      options: options,
      correctIndex: correctIndex,
      word: word.word,
    );
  }

  QuizQuestion _createAntonymQuestion(WordDefinition word) {
    final random = Random();
    final antonyms = word.meanings
        .expand((m) => m.antonyms)
        .where((s) => s.isNotEmpty)
        .toList();
    
    final correctAntonym = antonyms[random.nextInt(antonyms.length)];
    
    List<String> wrongAnswers = [
      'similar',
      'equivalent',
      'identical',
    ];
    
    List<String> options = [correctAntonym, ...wrongAnswers];
    options.shuffle();
    
    final correctIndex = options.indexOf(correctAntonym);
    
    return QuizQuestion(
      question: 'Which word is an antonym of "${word.word}"?',
      options: options,
      correctIndex: correctIndex,
      word: word.word,
    );
  }

  void _selectAnswer(int index) {
    if (_showAnswer) return;
    
    setState(() {
      _selectedAnswer = index;
      _showAnswer = true;
      _totalQuestions++;
      
      if (index == _currentQuestion!.correctIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    _generateQuizQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4B4B),
        foregroundColor: Colors.white,
        title: const Text('Dictionary & Quiz'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_quizMode ? Icons.search : Icons.quiz),
            onPressed: () {
              setState(() {
                _quizMode = !_quizMode;
                if (_quizMode && _currentQuestion == null) {
                  _generateQuizQuestion();
                }
              });
            },
          ),
        ],
      ),
      body: _quizMode ? _buildQuizMode() : _buildDictionaryMode(),
    );
  }

  Widget _buildDictionaryMode() {
    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a word...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF4B4B)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _currentWord = null;
                    _error = null;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF4B4B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF4B4B), width: 2),
              ),
            ),
            onSubmitted: _searchWord,
          ),
        ),
        
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B4B)))
              : _error != null
                  ? _buildErrorState()
                  : _currentWord != null
                      ? _buildWordDetails()
                      : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildQuizMode() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score: $_score / $_totalQuestions',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _totalQuestions > 0 ? '${((_score / _totalQuestions) * 100).round()}%' : '0%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4B4B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Quiz Content
          Expanded(
            child: _isGeneratingQuestion
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B4B)))
                : _currentQuestion != null
                    ? _buildQuizQuestion()
                    : _buildQuizEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _currentQuestion!.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Options
        ...List.generate(_currentQuestion!.options.length, (index) {
          final isSelected = _selectedAnswer == index;
          final isCorrect = index == _currentQuestion!.correctIndex;
          final showResult = _showAnswer;
          
          Color? cardColor;
          if (showResult) {
            if (isCorrect) {
              cardColor = Colors.green.shade100;
            } else if (isSelected && !isCorrect) {
              cardColor = Colors.red.shade100;
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: cardColor,
              child: ListTile(
                title: Text(_currentQuestion!.options[index]),
                leading: showResult && isCorrect
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : showResult && isSelected && !isCorrect
                        ? const Icon(Icons.cancel, color: Colors.red)
                        : null,
                onTap: () => _selectAnswer(index),
              ),
            ),
          );
        }),
        
        const SizedBox(height: 20),
        
        // Next Button
        if (_showAnswer)
          ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Next Question', style: TextStyle(fontSize: 16)),
          ),
      ],
    );
  }

  Widget _buildQuizEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.quiz, size: 80, color: Color(0xFFFF4B4B)),
          const SizedBox(height: 20),
          const Text(
            'Quiz Mode',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Test your vocabulary knowledge with random words!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _generateQuizQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Start Quiz', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildWordDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Word Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentWord!.word,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF4B4B),
                          ),
                        ),
                      ),
                      if (_currentWord!.audioUrls.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Color(0xFFFF4B4B)),
                          onPressed: () => _playAudio(_currentWord!.audioUrls.first),
                        ),
                    ],
                  ),
                  if (_currentWord!.phonetic.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentWord!.phonetic,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Meanings
          ...List.generate(_currentWord!.meanings.length, (index) {
            final meaning = _currentWord!.meanings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Part of Speech
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B4B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meaning.partOfSpeech,
                        style: const TextStyle(
                          color: Color(0xFFFF4B4B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Definitions
                    ...List.generate(meaning.definitions.length, (defIndex) {
                      final definition = meaning.definitions[defIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${defIndex + 1}. ${definition.definition}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (definition.example != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Example: "${definition.example}"',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    
                    // Synonyms
                    if (meaning.synonyms.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Synonyms:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: meaning.synonyms.map((synonym) => Chip(
                          label: Text(synonym),
                          backgroundColor: Colors.green.shade100,
                        )).toList(),
                      ),
                    ],
                    
                    // Antonyms
                    if (meaning.antonyms.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Antonyms:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: meaning.antonyms.map((antonym) => Chip(
                          label: Text(antonym),
                          backgroundColor: Colors.red.shade100,
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          
          // Origin
          if (_currentWord!.origin != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Etymology',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF4B4B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentWord!.origin!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'English Dictionary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Search for any word to see its definition,\npronunciation, and more!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Oops!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B),
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
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
