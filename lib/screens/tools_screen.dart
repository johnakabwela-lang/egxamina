import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ultsukulu/screens/calculator.dart';
import 'package:ultsukulu/screens/notepad.dart';
import 'package:ultsukulu/screens/periodic_table.dart';
import 'package:ultsukulu/screens/schedule_maker.dart';
import 'package:ultsukulu/screens/study_timer.dart';
import 'package:ultsukulu/screens/unit_converter.dart';
import 'package:ultsukulu/screens/wiki_browser.dart';
import 'dictionary_screen.dart';

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
