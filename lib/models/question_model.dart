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
    try {
      // Validate correctAnswer is within bounds
      if (correctAnswer < 0 || correctAnswer >= options.length) {
        throw ArgumentError(
          'correctAnswer ($correctAnswer) must be between 0 and ${options.length - 1}',
        );
      }

      // Validate options is not empty
      if (options.isEmpty) {
        throw ArgumentError('options cannot be empty');
      }

      _originalOptions = List.from(options);
      _originalCorrectAnswer = correctAnswer;

      print('Question created successfully with ${options.length} options');
    } catch (e) {
      print('Error creating Question: $e');
      rethrow;
    }
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    try {
      // Validate required fields exist
      if (!json.containsKey('question')) {
        throw FormatException('Missing required field: question');
      }

      if (!json.containsKey('options')) {
        throw FormatException('Missing required field: options');
      }

      if (!json.containsKey('correctAnswer')) {
        throw FormatException('Missing required field: correctAnswer');
      }

      // Parse and validate options
      List<String> parsedOptions;
      try {
        parsedOptions = List<String>.from(json['options']);
      } catch (e) {
        print('Error parsing options: $e');
        throw FormatException('options must be a list of strings');
      }

      if (parsedOptions.isEmpty) {
        throw FormatException('options cannot be empty');
      }

      // Parse and validate correctAnswer
      int parsedCorrectAnswer;
      try {
        parsedCorrectAnswer = json['correctAnswer'] as int;
      } catch (e) {
        print('Error parsing correctAnswer: $e');
        throw FormatException('correctAnswer must be an integer');
      }

      if (parsedCorrectAnswer < 0 ||
          parsedCorrectAnswer >= parsedOptions.length) {
        throw FormatException(
          'correctAnswer ($parsedCorrectAnswer) must be between 0 and ${parsedOptions.length - 1}',
        );
      }

      return Question(
        id: json['id'] as int?,
        question:
            json['question'] as String? ?? '', // Handle null/missing question
        questionType: json['questionType'] as String?, // Can be null
        options: parsedOptions,
        correctAnswer: parsedCorrectAnswer,
        explanation: json['explanation'] as String?,
        reference: json['reference'] as String?,
        imagePath: json['imagePath'] as String?,
      );
    } catch (e) {
      print('Error creating Question from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    try {
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
    } catch (e) {
      print('Error converting Question to JSON: $e');
      rethrow;
    }
  }

  // Helper methods to check question type
  bool get isTextOnly {
    try {
      return questionType == 'text' || questionType == null;
    } catch (e) {
      print('Error checking if question is text only: $e');
      return false;
    }
  }

  bool get isTextWithImage {
    try {
      return questionType == 'text_with_image';
    } catch (e) {
      print('Error checking if question is text with image: $e');
      return false;
    }
  }

  bool get isImageOnly {
    try {
      return questionType == 'image_only';
    } catch (e) {
      print('Error checking if question is image only: $e');
      return false;
    }
  }

  bool get hasImage {
    try {
      return imagePath != null && imagePath!.isNotEmpty;
    } catch (e) {
      print('Error checking if question has image: $e');
      return false;
    }
  }

  bool get hasText {
    try {
      return question.isNotEmpty;
    } catch (e) {
      print('Error checking if question has text: $e');
      return false;
    }
  }

  void shuffleOptions() {
    try {
      if (options.isEmpty) {
        throw StateError('Cannot shuffle empty options list');
      }

      List<MapEntry<int, String>> indexedOptions = [];
      for (int i = 0; i < options.length; i++) {
        indexedOptions.add(MapEntry(i, options[i]));
      }

      indexedOptions.shuffle(Random());

      // Find the new position of the correct answer
      int newCorrectAnswer = -1;
      for (int i = 0; i < indexedOptions.length; i++) {
        options[i] = indexedOptions[i].value;
        if (indexedOptions[i].key == _originalCorrectAnswer) {
          newCorrectAnswer = i;
        }
      }

      if (newCorrectAnswer == -1) {
        throw StateError('Failed to track correct answer during shuffle');
      }

      correctAnswer = newCorrectAnswer;
      print(
        'Options shuffled successfully. New correct answer index: $correctAnswer',
      );
    } catch (e) {
      print('Error shuffling options: $e');
      // Restore original state on error
      try {
        resetOptions();
        print('Options restored to original state after shuffle error');
      } catch (resetError) {
        print('Failed to restore options after shuffle error: $resetError');
      }
    }
  }

  void resetOptions() {
    try {
      if (_originalOptions.isEmpty) {
        throw StateError('Original options are empty, cannot reset');
      }

      options.clear();
      options.addAll(_originalOptions);
      correctAnswer = _originalCorrectAnswer;
      print('Options reset to original state successfully');
    } catch (e) {
      print('Error resetting options: $e');
      rethrow;
    }
  }

  // Additional validation method
  bool validate() {
    try {
      if (question.isEmpty) {
        print('Validation error: Question text is empty');
        return false;
      }

      if (options.isEmpty) {
        print('Validation error: Options list is empty');
        return false;
      }

      if (correctAnswer < 0 || correctAnswer >= options.length) {
        print(
          'Validation error: correctAnswer ($correctAnswer) is out of bounds for options length ${options.length}',
        );
        return false;
      }

      if (options.any((option) => option.isEmpty)) {
        print('Validation error: One or more options are empty');
        return false;
      }

      print('Question validation passed');
      return true;
    } catch (e) {
      print('Error during validation: $e');
      return false;
    }
  }

  @override
  String toString() {
    try {
      return 'Question(id: $id, question: "${question.length > 50 ? question.substring(0, 50) + "..." : question}", options: ${options.length}, correctAnswer: $correctAnswer)';
    } catch (e) {
      print('Error in toString(): $e');
      return 'Question(error: $e)';
    }
  }
}

// Example usage with error handling
void main() {
  try {
    // Test normal creation
    var question1 = Question(
      question: "What is 2 + 2?",
      options: ["1", "2", "3", "4"],
      correctAnswer: 3,
    );
    print('Created question: $question1');

    // Test validation
    question1.validate();

    // Test shuffling
    question1.shuffleOptions();

    // Test JSON conversion
    var json = question1.toJson();
    print('JSON: $json');

    var fromJson = Question.fromJson(json);
    print('From JSON: $fromJson');

    // Test error cases
    print('\n--- Testing error cases ---');

    // Test invalid correctAnswer
    try {
      var invalidQuestion = Question(
        question: "Test?",
        options: ["A", "B"],
        correctAnswer: 5, // Out of bounds
      );
    } catch (e) {
      print('Caught expected error for invalid correctAnswer: $e');
    }

    // Test empty options
    try {
      var emptyOptionsQuestion = Question(
        question: "Test?",
        options: [],
        correctAnswer: 0,
      );
    } catch (e) {
      print('Caught expected error for empty options: $e');
    }

    // Test invalid JSON
    try {
      var invalidJson = Question.fromJson({
        'question': 'Test?',
        'options': ['A', 'B'],
        // Missing correctAnswer
      });
    } catch (e) {
      print('Caught expected error for invalid JSON: $e');
    }
  } catch (e) {
    print('Unexpected error in main: $e');
  }
}
