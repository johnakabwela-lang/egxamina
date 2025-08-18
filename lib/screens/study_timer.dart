import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ultsukulu/widgets/press_affected_widget.dart';

class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 25 * 60; // Default 25 minutes
  bool _isRunning = false;
  bool _isBreakTime = false;

  // Timer settings
  int _studyMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;

  // Statistics
  int _completedSessions = 0;
  int _totalStudyTime = 0; // in minutes

  // Animation controllers
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _studyMinutes * 60;

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pressAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isBreakTime
          ? (_completedSessions % 4 == 3
                    ? _longBreakMinutes
                    : _shortBreakMinutes) *
                60
          : _studyMinutes * 60;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;

      if (_isBreakTime) {
        // Break is over, start study session
        _isBreakTime = false;
        _remainingSeconds = _studyMinutes * 60;
      } else {
        // Study session complete
        _completedSessions++;
        _totalStudyTime += _studyMinutes;
        _isBreakTime = true;

        // Determine break length (long break every 4 sessions)
        int breakMinutes = _completedSessions % 4 == 0
            ? _longBreakMinutes
            : _shortBreakMinutes;
        _remainingSeconds = breakMinutes * 60;
      }
    });

    // Show completion dialog
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _isBreakTime ? 'Study Session Complete!' : 'Break Time Over!',
          ),
          content: Text(
            _isBreakTime
                ? 'Great work! Time for a ${_completedSessions % 4 == 0 ? "long" : "short"} break.'
                : 'Break time is over. Ready for another study session?',
          ),
          actions: [
            CustomPressEffectWidget(
              backgroundColor: Colors.grey[300]!,
              shadowColor: Colors.grey[700],
              isPressed: false,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              elevation: 4,
              pressedElevation: 1,
              buttonPressAnimation: _pressAnimation,
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CustomPressEffectWidget(
              backgroundColor: Colors.teal[400]!,
              shadowColor: Colors.teal.withOpacity(1),
              isPressed: false,
              borderRadius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.zero,
              elevation: 4,
              pressedElevation: 1,
              buttonPressAnimation: _pressAnimation,
              onTap: () {
                Navigator.of(context).pop();
                _startTimer();
              },
              child: const Text(
                'Start Next',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempStudy = _studyMinutes;
        int tempShortBreak = _shortBreakMinutes;
        int tempLongBreak = _longBreakMinutes;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Timer Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSliderSetting(
                    'Study Time',
                    tempStudy,
                    5,
                    60,
                    (value) => setDialogState(() => tempStudy = value),
                  ),
                  _buildSliderSetting(
                    'Short Break',
                    tempShortBreak,
                    1,
                    15,
                    (value) => setDialogState(() => tempShortBreak = value),
                  ),
                  _buildSliderSetting(
                    'Long Break',
                    tempLongBreak,
                    10,
                    30,
                    (value) => setDialogState(() => tempLongBreak = value),
                  ),
                ],
              ),
              actions: [
                CustomPressEffectWidget(
                  backgroundColor: Colors.grey[300]!,
                  shadowColor: Colors.grey[700],
                  isPressed: false,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  elevation: 4,
                  pressedElevation: 1,
                  buttonPressAnimation: _pressAnimation,
                  onTap: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CustomPressEffectWidget(
                  backgroundColor: Colors.teal[400]!,
                  shadowColor: Colors.teal[700],
                  isPressed: false,
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  margin: EdgeInsets.zero,
                  elevation: 4,
                  pressedElevation: 1,
                  buttonPressAnimation: _pressAnimation,
                  onTap: () {
                    setState(() {
                      _studyMinutes = tempStudy;
                      _shortBreakMinutes = tempShortBreak;
                      _longBreakMinutes = tempLongBreak;
                      _resetTimer();
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSliderSetting(
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value min'),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: Colors.teal[400]!,
          onChanged: (double val) => onChanged(val.round()),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.teal[400]!,
        foregroundColor: Colors.white,
        title: const Text('Study Timer'),
        elevation: 0,
        actions: [
          CustomPressEffectWidget(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            isPressed: false,
            borderRadius: 20,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
            elevation: 0,
            pressedElevation: 0,
            buttonPressAnimation: _pressAnimation,
            onTap: _showSettingsDialog,
            child: const Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Timer Status Card
              CustomPressEffectWidget(
                backgroundColor: _isBreakTime
                    ? Colors.green[400]!
                    : Colors.teal[400]!,
                shadowColor: _isBreakTime
                    ? Colors.green[700]
                    : Colors.teal[700],
                isPressed: false,
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 30),
                elevation: 8,
                pressedElevation: 2,
                onTap: null, // Non-interactive card
                child: Column(
                  children: [
                    Icon(
                      _isBreakTime ? Icons.coffee : Icons.school,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isBreakTime ? 'Break Time' : 'Study Session',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Timer Display Card
              CustomPressEffectWidget(
                backgroundColor: Colors.white,
                shadowColor: Colors.black.withOpacity(0.1),
                isPressed: false,
                borderRadius: 100,
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.only(bottom: 30),
                elevation: 12,
                pressedElevation: 4,
                onTap: null, // Non-interactive card
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRunning ? 'Running...' : 'Paused',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomPressEffectWidget(
                    backgroundColor: Colors.grey[400]!,
                    shadowColor: Colors.grey[700],
                    isPressed: false,
                    borderRadius: 30,
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    elevation: 8,
                    pressedElevation: 2,
                    buttonPressAnimation: _pressAnimation,
                    onTap: _resetTimer,
                    child: const SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(Icons.refresh, color: Colors.white, size: 24),
                    ),
                  ),
                  CustomPressEffectWidget(
                    backgroundColor: Colors.teal[400]!,
                    shadowColor: Colors.teal[700],
                    isPressed: false,
                    borderRadius: 35,
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    elevation: 10,
                    pressedElevation: 3,
                    buttonPressAnimation: _pressAnimation,
                    onTap: _isRunning ? _pauseTimer : _startTimer,
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  CustomPressEffectWidget(
                    backgroundColor: Colors.orange[400]!,
                    shadowColor: Colors.orange[700],
                    isPressed: false,
                    borderRadius: 30,
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    elevation: 8,
                    pressedElevation: 2,
                    buttonPressAnimation: _pressAnimation,
                    onTap: () => _onTimerComplete(),
                    child: const SizedBox(
                      width: 60,
                      height: 60,
                      child: Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Statistics Card
              CustomPressEffectWidget(
                backgroundColor: Colors.white,
                shadowColor: Colors.black.withOpacity(0.05),
                isPressed: false,
                borderRadius: 16,
                padding: const EdgeInsets.all(24),
                margin: EdgeInsets.zero,
                elevation: 8,
                pressedElevation: 2,
                onTap: null, // Non-interactive card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Completed Sessions',
                          '$_completedSessions',
                        ),
                        _buildStatItem(
                          'Total Study Time',
                          '${_totalStudyTime}min',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal[400]!,
          ),
        ),
      ],
    );
  }
}
