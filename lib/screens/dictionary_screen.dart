import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'phonetic': phonetic,
      'audioUrls': audioUrls,
      'meanings': meanings.map((m) => m.toJson()).toList(),
      'origin': origin,
    };
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

  Map<String, dynamic> toJson() {
    return {
      'partOfSpeech': partOfSpeech,
      'definitions': definitions.map((d) => d.toJson()).toList(),
      'synonyms': synonyms,
      'antonyms': antonyms,
    };
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

  Map<String, dynamic> toJson() {
    return {'definition': definition, 'example': example};
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String word;
  final String questionType;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.word,
    required this.questionType,
  });
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  WordDefinition? _currentWord;
  WordDefinition? _wordOfTheDay;
  bool _isLoading = false;
  String? _error;
  List<String> _searchHistory = [];
  List<WordDefinition> _favorites = [];

  // Quiz state
  QuizQuestion? _currentQuestion;
  int? _selectedAnswer;
  bool _showAnswer = false;
  int _score = 0;
  int _totalQuestions = 0;
  bool _isGeneratingQuestion = false;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _loadData();
    _loadWordOfTheDay();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
      _score = prefs.getInt('total_score') ?? 0;
      _totalQuestions = prefs.getInt('total_questions') ?? 0;
      _streak = prefs.getInt('current_streak') ?? 0;
    });

    // Load favorites
    final favoritesJson = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favorites = favoritesJson
          .map((json) => WordDefinition.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    await prefs.setInt('total_score', _score);
    await prefs.setInt('total_questions', _totalQuestions);
    await prefs.setInt('current_streak', _streak);

    // Save favorites
    final favoritesJson = _favorites
        .map((word) => jsonEncode(word.toJson()))
        .toList();
    await prefs.setStringList('favorites', favoritesJson);
  }

  Future<void> _loadWordOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString('wotd_date');

    if (lastDate != today) {
      // Generate new word of the day
      await _generateWordOfTheDay();
      await prefs.setString('wotd_date', today);
    } else {
      // Load existing word of the day
      final wotdJson = prefs.getString('wotd_data');
      if (wotdJson != null) {
        setState(() {
          _wordOfTheDay = WordDefinition.fromJson(jsonDecode(wotdJson));
        });
      } else {
        await _generateWordOfTheDay();
      }
    }
  }

  Future<void> _generateWordOfTheDay() async {
    final interestingWords = [
      'serendipity',
      'ephemeral',
      'petrichor',
      'wanderlust',
      'mellifluous',
      'aurora',
      'solitude',
      'cascade',
      'luminous',
      'whisper',
      'eloquent',
      'pristine',
      'tranquil',
      'magnificent',
      'ethereal',
    ];

    final randomWord =
        interestingWords[Random().nextInt(interestingWords.length)];

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.dictionaryapi.dev/api/v2/entries/en/$randomWord',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final wordOfTheDay = WordDefinition.fromJson(data[0]);
          setState(() {
            _wordOfTheDay = wordOfTheDay;
          });

          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('wotd_data', jsonEncode(wordOfTheDay.toJson()));
        }
      }
    } catch (e) {
      print('Failed to load word of the day: $e');
    }
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
          final wordDefinition = WordDefinition.fromJson(data[0]);
          setState(() {
            _currentWord = wordDefinition;
            _isLoading = false;
          });

          // Add to search history
          _addToSearchHistory(word.trim().toLowerCase());
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

  void _addToSearchHistory(String word) {
    setState(() {
      _searchHistory.remove(word);
      _searchHistory.insert(0, word);
      if (_searchHistory.length > 20) {
        _searchHistory = _searchHistory.take(20).toList();
      }
    });
    _saveData();
  }

  void _toggleFavorite(WordDefinition word) {
    setState(() {
      final index = _favorites.indexWhere((w) => w.word == word.word);
      if (index >= 0) {
        _favorites.removeAt(index);
      } else {
        _favorites.insert(0, word);
      }
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favorites.any((w) => w.word == word.word)
              ? 'Added to favorites'
              : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  bool _isFavorite(WordDefinition word) {
    return _favorites.any((w) => w.word == word.word);
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to play audio'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Quiz methods (improved)
  Future<void> _generateQuizQuestion() async {
    setState(() {
      _isGeneratingQuestion = true;
    });

    try {
      final List<Future<String?>> wordRequests = List.generate(
        4,
        (index) => _getRandomWord(),
      );
      final List<String?> randomWords = await Future.wait(wordRequests);

      final validWords = randomWords
          .where((word) => word != null)
          .cast<String>()
          .toList();

      if (validWords.length < 4) {
        _generateFallbackQuestion();
        return;
      }

      final List<Future<WordDefinition?>> definitionRequests = validWords
          .map((word) => _getWordDefinition(word))
          .toList();
      final List<WordDefinition?> definitions = await Future.wait(
        definitionRequests,
      );

      final validDefinitions = definitions
          .where((def) => def != null)
          .cast<WordDefinition>()
          .toList();

      if (validDefinitions.isEmpty) {
        _generateFallbackQuestion();
        return;
      }

      final correctWord = validDefinitions.first;
      final wrongWords = validDefinitions.skip(1).take(3).toList();

      final question = await _createImprovedQuestion(correctWord, wrongWords);

      setState(() {
        _currentQuestion = question;
        _selectedAnswer = null;
        _showAnswer = false;
        _isGeneratingQuestion = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingQuestion = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate quiz question')),
      );
    }
  }

  Future<String?> _getRandomWord() async {
    try {
      final response = await http.get(
        Uri.parse('https://random-word-api.vercel.app/api?words=1'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? data[0] : null;
      }
    } catch (e) {
      print('Error getting random word: $e');
    }
    return null;
  }

  Future<WordDefinition?> _getWordDefinition(String word) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? WordDefinition.fromJson(data[0]) : null;
      }
    } catch (e) {
      print('Error getting definition for $word: $e');
    }
    return null;
  }

  Future<QuizQuestion> _createImprovedQuestion(
    WordDefinition correctWord,
    List<WordDefinition> wrongWords,
  ) async {
    final random = Random();
    List<String> availableTypes = ['definition'];

    bool hasSynonyms = correctWord.meanings.any((m) => m.synonyms.isNotEmpty);
    bool hasAntonyms = correctWord.meanings.any((m) => m.antonyms.isNotEmpty);

    if (hasSynonyms) availableTypes.add('synonym');
    if (hasAntonyms) availableTypes.add('antonym');

    final questionType = availableTypes[random.nextInt(availableTypes.length)];

    switch (questionType) {
      case 'definition':
        return _createDefinitionQuestionWithRealWords(correctWord, wrongWords);
      case 'synonym':
        return _createSynonymQuestionImproved(correctWord, wrongWords);
      case 'antonym':
        return _createAntonymQuestionImproved(correctWord, wrongWords);
      default:
        return _createDefinitionQuestionWithRealWords(correctWord, wrongWords);
    }
  }

  QuizQuestion _createDefinitionQuestionWithRealWords(
    WordDefinition correctWord,
    List<WordDefinition> wrongWords,
  ) {
    final definition = correctWord.meanings[0].definitions[0].definition;

    List<String> wrongAnswers = wrongWords.map((w) => w.word).toList();

    while (wrongAnswers.length < 3) {
      wrongAnswers.add(_getGenericWrongAnswer());
    }
    wrongAnswers = wrongAnswers.take(3).toList();

    List<String> options = [correctWord.word, ...wrongAnswers];
    options.shuffle();

    final correctIndex = options.indexOf(correctWord.word);

    return QuizQuestion(
      question: 'What word matches this definition?\n\n"$definition"',
      options: options,
      correctIndex: correctIndex,
      word: correctWord.word,
      questionType: 'definition',
    );
  }

  QuizQuestion _createSynonymQuestionImproved(
    WordDefinition correctWord,
    List<WordDefinition> wrongWords,
  ) {
    final synonyms = correctWord.meanings
        .expand((m) => m.synonyms)
        .where((s) => s.isNotEmpty)
        .toList();

    final correctSynonym = synonyms[Random().nextInt(synonyms.length)];

    List<String> wrongAnswers = wrongWords.map((w) => w.word).take(3).toList();

    while (wrongAnswers.length < 3) {
      wrongAnswers.add(_getGenericWrongAnswer());
    }

    List<String> options = [correctSynonym, ...wrongAnswers];
    options.shuffle();

    final correctIndex = options.indexOf(correctSynonym);

    return QuizQuestion(
      question: 'Which word is a SYNONYM of "${correctWord.word}"?',
      options: options,
      correctIndex: correctIndex,
      word: correctWord.word,
      questionType: 'synonym',
    );
  }

  QuizQuestion _createAntonymQuestionImproved(
    WordDefinition correctWord,
    List<WordDefinition> wrongWords,
  ) {
    final antonyms = correctWord.meanings
        .expand((m) => m.antonyms)
        .where((s) => s.isNotEmpty)
        .toList();

    final correctAntonym = antonyms[Random().nextInt(antonyms.length)];

    List<String> wrongAnswers = wrongWords.map((w) => w.word).take(3).toList();

    while (wrongAnswers.length < 3) {
      wrongAnswers.add(_getGenericWrongAnswer());
    }

    List<String> options = [correctAntonym, ...wrongAnswers];
    options.shuffle();

    final correctIndex = options.indexOf(correctAntonym);

    return QuizQuestion(
      question: 'Which word is an ANTONYM of "${correctWord.word}"?',
      options: options,
      correctIndex: correctIndex,
      word: correctWord.word,
      questionType: 'antonym',
    );
  }

  void _generateFallbackQuestion() {
    final fallbackWords = ['computer', 'telephone', 'elephant', 'butterfly'];
    final random = Random();
    final selectedWord = fallbackWords[random.nextInt(fallbackWords.length)];

    _searchWord(selectedWord).then((_) {
      if (_currentWord != null) {
        final question = _createDefinitionQuestion(_currentWord!);
        setState(() {
          _currentQuestion = question;
          _selectedAnswer = null;
          _showAnswer = false;
          _isGeneratingQuestion = false;
        });
      }
    });
  }

  String _getGenericWrongAnswer() {
    final genericWords = [
      'mountain',
      'ocean',
      'building',
      'vehicle',
      'instrument',
      'animal',
      'plant',
      'technology',
      'weather',
      'music',
    ];
    return genericWords[Random().nextInt(genericWords.length)];
  }

  QuizQuestion _createDefinitionQuestion(WordDefinition word) {
    final definition = word.meanings[0].definitions[0].definition;

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
      questionType: 'definition',
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
        _streak++;
      } else {
        _streak = 0;
      }
    });
    _saveData();
  }

  void _nextQuestion() {
    _generateQuizQuestion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Dictionary & Quiz'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [_buildSearchTab(), _buildQuizTab(), _buildFavoritesTab()],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        // Word of the Day Card
        if (_wordOfTheDay != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.indigo, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Word of the Day',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _generateWordOfTheDay,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _wordOfTheDay!.word,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_wordOfTheDay!.audioUrls.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _playAudio(_wordOfTheDay!.audioUrls.first),
                          ),
                      ],
                    ),
                    if (_wordOfTheDay!.phonetic.isNotEmpty)
                      Text(
                        _wordOfTheDay!.phonetic,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _wordOfTheDay!
                          .meanings
                          .first
                          .definitions
                          .first
                          .definition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _currentWord = _wordOfTheDay;
                          });
                        },
                        child: const Text(
                          'Learn More',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Search Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a word...',
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _currentWord = null;
                              _error = null;
                            });
                          },
                        ),
                      if (_searchHistory.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.history),
                          onPressed: _showSearchHistory,
                        ),
                    ],
                  ),
                ),
                onSubmitted: _searchWord,
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Content
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.indigo),
                )
              : _error != null
              ? _buildErrorState()
              : _currentWord != null
              ? _buildWordDetails()
              : _buildSearchEmptyState(),
        ),
      ],
    );
  }

  Widget _buildQuizTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Score',
                  '$_score / $_totalQuestions',
                  Icons.score,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Accuracy',
                  _totalQuestions > 0
                      ? '${((_score / _totalQuestions) * 100).round()}%'
                      : '0%',
                  Icons.donut_large_outlined,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Streak',
                  '$_streak',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quiz Content
          Expanded(
            child: _isGeneratingQuestion
                ? _buildQuizLoadingState()
                : _currentQuestion != null
                ? _buildQuizQuestion()
                : _buildQuizEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return _favorites.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  'No Favorites Yet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Search for words and add them to favorites!',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final word = _favorites[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    word.word,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (word.phonetic.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          word.phonetic,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        word.meanings.first.definitions.first.definition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (word.audioUrls.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => _playAudio(word.audioUrls.first),
                        ),
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () => _toggleFavorite(word),
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      _currentWord = word;
                      _tabController.animateTo(0);
                    });
                  },
                ),
              );
            },
          );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.indigo),
        const SizedBox(height: 20),
        const Text(
          'Generating Question...',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Fetching words and definitions',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildQuizQuestion() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Question type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _currentQuestion!.questionType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentQuestion!.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
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
            Color? iconColor;
            IconData? icon;

            if (showResult) {
              if (isCorrect) {
                cardColor = Colors.green.shade50;
                iconColor = Colors.green;
                icon = Icons.check_circle;
              } else if (isSelected && !isCorrect) {
                cardColor = Colors.red.shade50;
                iconColor = Colors.red;
                icon = Icons.cancel;
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isSelected ? 4 : 2,
                color: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: Colors.indigo, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    _currentQuestion!.options[index],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  leading: icon != null
                      ? Icon(icon, color: iconColor)
                      : CircleAvatar(
                          backgroundColor: Colors.indigo.withOpacity(0.1),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  onTap: () => _selectAnswer(index),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Action Button
          if (_showAnswer) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Next Question',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedAnswer == _currentQuestion!.correctIndex)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.celebration, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _streak > 1
                              ? 'Correct! You\'re on a $_streak question streak! 🔥'
                              : 'Correct! Well done! 🎉',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildQuizEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz, size: 64, color: Colors.indigo),
          ),
          const SizedBox(height: 24),
          const Text(
            'Enhanced Quiz Mode',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Test your vocabulary with real words!\nEach question uses multiple API calls for better variety.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateQuizQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Quiz', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showSearchHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Search History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _searchHistory.length,
                  itemBuilder: (context, index) {
                    final word = _searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(word),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _searchHistory.removeAt(index);
                          });
                          _saveData();
                          Navigator.pop(context);
                          if (_searchHistory.isNotEmpty) {
                            _showSearchHistory();
                          }
                        },
                      ),
                      onTap: () {
                        _searchController.text = word;
                        _searchWord(word);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              if (_searchHistory.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _searchHistory.clear();
                      });
                      _saveData();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All History'),
                  ),
                ),
            ],
          ),
        ),
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
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentWord!.word,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            if (_currentWord!.phonetic.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _currentWord!.phonetic,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentWord!.audioUrls.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.indigo,
                              ),
                              onPressed: () =>
                                  _playAudio(_currentWord!.audioUrls.first),
                            ),
                          IconButton(
                            icon: Icon(
                              _isFavorite(_currentWord!)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                            ),
                            onPressed: () => _toggleFavorite(_currentWord!),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Meanings
          ...List.generate(_currentWord!.meanings.length, (index) {
            final meaning = _currentWord!.meanings[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meaning.partOfSpeech,
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Definitions
                    ...List.generate(
                      meaning.definitions
                          .take(3)
                          .length, // Limit to 3 definitions
                      (defIndex) {
                        final definition = meaning.definitions[defIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${defIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.indigo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          definition.definition,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (definition.example != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.fromBorderSide(
                                                BorderSide(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              '"${definition.example}"',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Show more definitions if there are any
                    if (meaning.definitions.length > 3) ...[
                      TextButton(
                        onPressed: () {
                          // Could implement expansion logic here
                        },
                        child: Text(
                          'Show ${meaning.definitions.length - 3} more definitions',
                        ),
                      ),
                    ],

                    // Synonyms
                    if (meaning.synonyms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Synonyms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: meaning.synonyms
                            .take(6)
                            .map(
                              (synonym) => ActionChip(
                                label: Text(synonym),
                                backgroundColor: Colors.green.shade50,
                                side: BorderSide(color: Colors.green.shade200),
                                onPressed: () => _searchWord(synonym),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    // Antonyms
                    if (meaning.antonyms.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Antonyms',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: meaning.antonyms
                            .take(6)
                            .map(
                              (antonym) => ActionChip(
                                label: Text(antonym),
                                backgroundColor: Colors.red.shade50,
                                side: BorderSide(color: Colors.red.shade200),
                                onPressed: () => _searchWord(antonym),
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

          // Origin/Etymology
          if (_currentWord!.origin != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_edu, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Etymology',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentWord!.origin!,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Add some padding at the bottom
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book, size: 64, color: Colors.indigo),
          ),
          const SizedBox(height: 24),
          const Text(
            'English Dictionary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Search for any word to see its definition,\npronunciation, examples, and more!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          if (_searchHistory.isNotEmpty) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: _showSearchHistory,
              icon: const Icon(Icons.history),
              label: const Text('View Search History'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, size: 64, color: Colors.red),
          ),
          const SizedBox(height: 24),
          const Text(
            'Word Not Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _searchController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              if (_searchHistory.isNotEmpty) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showSearchHistory,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.history),
                  label: const Text('Search History'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
