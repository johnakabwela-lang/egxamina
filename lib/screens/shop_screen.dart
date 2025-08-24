import 'package:flutter/material.dart';

import 'dart:ui';

import 'package:ultsukulu/managers/token_manager.dart';

class TokenShopScreen extends StatefulWidget {
  final VoidCallback onTokensUpdated;

  const TokenShopScreen({super.key, required this.onTokensUpdated});

  @override
  _TokenShopScreenState createState() => _TokenShopScreenState();
}

class _TokenShopScreenState extends State<TokenShopScreen> {
  TokenStats? _tokenStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenStats();
  }

  Future<void> _loadTokenStats() async {
    final stats = await TokenManager.instance.getTokenStats();
    setState(() {
      _tokenStats = stats;
      _isLoading = false;
    });
  }

  Future<void> _claimDailyBonus() async {
    final result = await TokenManager.instance.claimDailyBonus();

    if (result.success) {
      await _loadTokenStats();
      widget.onTokensUpdated();
      _showSuccessMessage(result.message);
    } else {
      _showErrorMessage(result.message);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _formatDuration(Duration duration) {
    int hours = duration.inHours;
    int minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.amber.shade600],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Token Shop'),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Balance Card
            if (!_isLoading && _tokenStats != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.amber.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_tokenStats!.currentTokens}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'tokens',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (_isLoading) ...[
              const SizedBox(height: 100),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading token information...'),
            ] else if (_tokenStats != null) ...[
              // Daily Bonus Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _tokenStats!.dailyBonusAvailable
                        ? [Colors.amber.shade100, Colors.amber.shade200]
                        : [Colors.grey.shade100, Colors.grey.shade200],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _tokenStats!.dailyBonusAvailable
                        ? Colors.amber.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: _tokenStats!.dailyBonusAvailable
                              ? Colors.amber.shade700
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Bonus',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _tokenStats!.dailyBonusAvailable
                                      ? Colors.amber.shade800
                                      : Colors.grey[700],
                                ),
                              ),
                              Text(
                                _tokenStats!.dailyBonusAvailable
                                    ? 'Claim ${TokenManager.DAILY_BONUS} free tokens!'
                                    : 'Next bonus in ${_formatDuration(_tokenStats!.nextDailyBonus)}',
                                style: TextStyle(
                                  color: _tokenStats!.dailyBonusAvailable
                                      ? Colors.amber.shade700
                                      : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_tokenStats!.dailyBonusAvailable) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _claimDailyBonus,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Claim Daily Bonus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // How to Earn Tokens Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'How to Earn Tokens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildEarnMethod(
                      'Daily Bonus',
                      '${TokenManager.DAILY_BONUS} tokens',
                      'Claim once per day',
                      Icons.calendar_today,
                    ),
                    _buildEarnMethod(
                      'Quiz Completion',
                      '5-30 tokens',
                      'Based on your score',
                      Icons.quiz,
                    ),
                    _buildEarnMethod(
                      'Streak Bonus',
                      '5+ tokens',
                      'Keep your daily streak alive',
                      Icons.local_fire_department,
                    ),
                    _buildEarnMethod(
                      'Perfect Score',
                      '30 tokens',
                      'Score 90% or higher',
                      Icons.stars,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Token Statistics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Earned',
                            '${_tokenStats!.totalEarned}',
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Spent',
                            '${_tokenStats!.totalSpent}',
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEarnMethod(
    String title,
    String amount,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
