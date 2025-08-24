import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static TokenManager? _instance;
  static TokenManager get instance => _instance ??= TokenManager._();

  TokenManager._();

  static const String _tokenKey = 'user_tokens';
  static const String _lastDailyBonusKey = 'last_daily_bonus';
  static const String _totalTokensEarnedKey = 'total_tokens_earned';
  static const String _totalTokensSpentKey = 'total_tokens_spent';

  // Token costs for different actions
  static const int QUIZ_COST = 10;
  static const int DAILY_BONUS = 50;
  static const int STREAK_BONUS_BASE = 5;
  static const int INITIAL_TOKENS = 100;

  // Get current token balance
  Future<int> getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_tokenKey) ?? INITIAL_TOKENS;
  }

  // Add tokens to user's balance
  Future<bool> addTokens(int amount, {String reason = 'Unknown'}) async {
    if (amount <= 0) return false;

    final prefs = await SharedPreferences.getInstance();
    final currentTokens = await getTokens();
    final newBalance = currentTokens + amount;

    await prefs.setInt(_tokenKey, newBalance);
    await _updateTotalEarned(amount);

    return true;
  }

  // Spend tokens (returns true if successful)
  Future<bool> spendTokens(int amount, {String reason = 'Unknown'}) async {
    if (amount <= 0) return false;

    final currentTokens = await getTokens();
    if (currentTokens < amount) {
      return false; // Insufficient tokens
    }

    final prefs = await SharedPreferences.getInstance();
    final newBalance = currentTokens - amount;

    await prefs.setInt(_tokenKey, newBalance);
    await _updateTotalSpent(amount);
    return true;
  }

  // Check if user has enough tokens
  Future<bool> hasEnoughTokens(int amount) async {
    final currentTokens = await getTokens();
    return currentTokens >= amount;
  }

  // Try to start a quiz (deduct tokens if available)
  Future<QuizStartResult> tryStartQuiz() async {
    final hasTokens = await hasEnoughTokens(QUIZ_COST);

    if (!hasTokens) {
      final currentTokens = await getTokens();
      return QuizStartResult(
        success: false,
        message:
            'Insufficient tokens! You need $QUIZ_COST tokens but only have $currentTokens.',
        tokensNeeded: QUIZ_COST - currentTokens,
      );
    }

    final success = await spendTokens(QUIZ_COST, reason: 'Quiz attempt');
    return QuizStartResult(
      success: success,
      message: success
          ? 'Quiz started! $QUIZ_COST tokens deducted.'
          : 'Failed to start quiz.',
      tokensNeeded: 0,
    );
  }

  // Award tokens for completing quiz
  Future<void> awardQuizCompletion(int score, int totalQuestions) async {
    final percentage = (score / totalQuestions * 100).round();
    int tokensAwarded = 0;

    if (percentage >= 90) {
      tokensAwarded = 30; // Excellent
    } else if (percentage >= 80) {
      tokensAwarded = 25; // Very Good
    } else if (percentage >= 70) {
      tokensAwarded = 20; // Good
    } else if (percentage >= 60) {
      tokensAwarded = 15; // Fair
    } else {
      tokensAwarded = 5; // Participation
    }

    await addTokens(tokensAwarded, reason: 'Quiz completion ($percentage%)');
  }

  // Award streak bonus
  Future<void> awardStreakBonus(int streakDays) async {
    if (streakDays <= 0) return;

    int bonus = STREAK_BONUS_BASE;
    if (streakDays >= 7) bonus *= 2; // Week streak
    if (streakDays >= 30) bonus *= 3; // Month streak
    if (streakDays >= 100) bonus *= 4; // Legendary streak

    await addTokens(bonus, reason: 'Streak bonus ($streakDays days)');
  }

  // Daily bonus system
  Future<DailyBonusResult> claimDailyBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBonusString = prefs.getString(_lastDailyBonusKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastBonusString == todayString) {
      return DailyBonusResult(
        success: false,
        message: 'Daily bonus already claimed today!',
        tokensAwarded: 0,
        nextBonusIn: _getTimeUntilMidnight(),
      );
    }

    await addTokens(DAILY_BONUS, reason: 'Daily bonus');
    await prefs.setString(_lastDailyBonusKey, todayString);

    return DailyBonusResult(
      success: true,
      message: 'Daily bonus claimed! +$DAILY_BONUS tokens',
      tokensAwarded: DAILY_BONUS,
      nextBonusIn: const Duration(hours: 24),
    );
  }

  // Check if daily bonus is available
  Future<bool> isDailyBonusAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBonusString = prefs.getString(_lastDailyBonusKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    return lastBonusString != todayString;
  }

  // Get comprehensive token statistics
  Future<TokenStats> getTokenStats() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTokens = await getTokens();
    final totalEarned = prefs.getInt(_totalTokensEarnedKey) ?? INITIAL_TOKENS;
    final totalSpent = prefs.getInt(_totalTokensSpentKey) ?? 0;
    final dailyBonusAvailable = await isDailyBonusAvailable();

    return TokenStats(
      currentTokens: currentTokens,
      totalEarned: totalEarned,
      totalSpent: totalSpent,
      dailyBonusAvailable: dailyBonusAvailable,
      nextDailyBonus: dailyBonusAvailable
          ? Duration.zero
          : _getTimeUntilMidnight(),
    );
  }

  // Reset tokens (for testing or admin purposes)
  Future<void> resetTokens({int amount = INITIAL_TOKENS}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenKey, amount);
    await prefs.remove(_totalTokensEarnedKey);
    await prefs.remove(_totalTokensSpentKey);
    await prefs.remove(_lastDailyBonusKey);
  }

  // Private helper methods
  Future<void> _updateTotalEarned(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalTokensEarnedKey) ?? 0;
    await prefs.setInt(_totalTokensEarnedKey, current + amount);
  }

  Future<void> _updateTotalSpent(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalTokensSpentKey) ?? 0;
    await prefs.setInt(_totalTokensSpentKey, current + amount);
  }

  Duration _getTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }
}

// Result classes
class QuizStartResult {
  final bool success;
  final String message;
  final int tokensNeeded;

  QuizStartResult({
    required this.success,
    required this.message,
    required this.tokensNeeded,
  });
}

class DailyBonusResult {
  final bool success;
  final String message;
  final int tokensAwarded;
  final Duration nextBonusIn;

  DailyBonusResult({
    required this.success,
    required this.message,
    required this.tokensAwarded,
    required this.nextBonusIn,
  });
}

class TokenStats {
  final int currentTokens;
  final int totalEarned;
  final int totalSpent;
  final bool dailyBonusAvailable;
  final Duration nextDailyBonus;

  TokenStats({
    required this.currentTokens,
    required this.totalEarned,
    required this.totalSpent,
    required this.dailyBonusAvailable,
    required this.nextDailyBonus,
  });
}

// Token display widget
class TokenDisplayer extends StatelessWidget {
  final int tokens;
  final bool showAnimation;
  final VoidCallback? onTap;

  const TokenDisplayer({
    super.key,
    required this.tokens,
    this.showAnimation = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade400, Colors.amber.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              tokens.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
