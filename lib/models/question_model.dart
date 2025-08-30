import 'dart:math';

class Question {
  final int? id;
  final String question;
  final String? questionType;
  final List<String> options;
  int correctAnswer; // Removed final to allow shuffling
  final String? explanation;
  final String? reference;
  final String? imagePath;

  // Store original options and correct answer for shuffling
  late List<String> _originalOptions;
  late int _originalCorrectAnswer;

  Question({
    this.id,
    required this.question,
    this.questionType,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.reference,
    this.imagePath,
  }) {
    _originalOptions = List.from(options);
    _originalCorrectAnswer = correctAnswer;
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int?,
      question:
          json['question'] as String? ??
          '', // Handle empty question for image-only questions
      questionType: json['questionType'] as String?,
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String?,
      reference: json['reference'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'question': question,
      if (questionType != null) 'questionType': questionType,
      'options': options,
      'correctAnswer': correctAnswer,
      if (explanation != null) 'explanation': explanation,
      if (reference != null) 'reference': reference,
      if (imagePath != null) 'imagePath': imagePath,
    };
  }

  // Helper methods to check question type
  bool get isTextOnly => questionType == 'text';
  bool get isTextWithImage => questionType == 'text_with_image';
  bool get isImageOnly => questionType == 'image_only';
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;
  bool get hasText => question.isNotEmpty;

  void shuffleOptions() {
    List<MapEntry<int, String>> indexedOptions = [];
    for (int i = 0; i < options.length; i++) {
      indexedOptions.add(MapEntry(i, options[i]));
    }

    indexedOptions.shuffle(Random());

    for (int i = 0; i < indexedOptions.length; i++) {
      options[i] = indexedOptions[i].value;
      if (indexedOptions[i].key == _originalCorrectAnswer) {
        correctAnswer = i;
      }
    }
  }

  void resetOptions() {
    options.clear();
    options.addAll(_originalOptions);
    correctAnswer = _originalCorrectAnswer;
  }
}
