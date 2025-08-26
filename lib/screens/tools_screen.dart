import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultsukulu/screens/calculator.dart';
import 'package:ultsukulu/screens/notepad.dart';
import 'package:ultsukulu/screens/periodic_table.dart';
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
        if (phonetic['audio'] != null &&
            phonetic['audio'].toString().isNotEmpty) {
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

  Definition({required this.definition, this.example});

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
        Uri.parse(
          'https://api.dictionaryapi.dev/api/v2/entries/en/${word.trim()}',
        ),
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
        _error =
            'Failed to fetch word definition. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to play audio')));
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
          Uri.parse(
            'https://api.dictionaryapi.dev/api/v2/entries/en/$randomWord',
          ),
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

    List<String> wrongAnswers = ['completely', 'hardly', 'never'];

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

    List<String> wrongAnswers = ['similar', 'equivalent', 'identical'];

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
                borderSide: const BorderSide(
                  color: Color(0xFFFF4B4B),
                  width: 2,
                ),
              ),
            ),
            onSubmitted: _searchWord,
          ),
        ),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
                )
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _totalQuestions > 0
                        ? '${((_score / _totalQuestions) * 100).round()}%'
                        : '0%',
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
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
                  )
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
                          icon: const Icon(
                            Icons.volume_up,
                            color: Color(0xFFFF4B4B),
                          ),
                          onPressed: () =>
                              _playAudio(_currentWord!.audioUrls.first),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                        children: meaning.synonyms
                            .map(
                              (synonym) => Chip(
                                label: Text(synonym),
                                backgroundColor: Colors.green.shade100,
                              ),
                            )
                            .toList(),
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
                        children: meaning.antonyms
                            .map(
                              (antonym) => Chip(
                                label: Text(antonym),
                                backgroundColor: Colors.red.shade100,
                              ),
                            )
                            .toList(),
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
          Icon(Icons.menu_book, size: 80, color: Colors.grey.shade400),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
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
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
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
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
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
