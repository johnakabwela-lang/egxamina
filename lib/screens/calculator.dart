import 'package:flutter/material.dart';
import 'dart:math' as math;

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  String display = '0';
  String equation = '';
  double result = 0;
  String operation = '';
  double operand = 0;
  bool shouldResetDisplay = false;
  bool isScientificMode = false;
  List<String> history = [];
  late AnimationController _animationController;

  // Modern dark theme color scheme
  static const Color primaryGradientStart = Color(0xFF667eea);
  static const Color primaryGradientEnd = Color(0xFF764ba2);
  static const Color secondaryGradientStart = Color(0xFF4facfe);
  static const Color secondaryGradientEnd = Color(0xFF00f2fe);
  static const Color backgroundColor = Color(0xFF0a0a0a);
  static const Color surfaceColor = Color(0xFF1a1a1a);
  static const Color surfaceVariant = Color(0xFF2a2a2a);
  static const Color textPrimary = Color(0xFFffffff);
  static const Color textSecondary = Color(0xFFb0b0b0);
  static const Color accentOrange = Color(0xFFff6b6b);
  static const Color accentGreen = Color(0xFF51cf66);
  static const Color operatorColor = Color(0xFF4c6ef5);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onButtonPressed(String buttonText) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      if (buttonText == 'C') {
        _clear();
      } else if (buttonText == 'CE') {
        _clearEntry();
      } else if (buttonText == '⌫') {
        _backspace();
      } else if (buttonText == '=') {
        _calculate();
      } else if (_isOperator(buttonText)) {
        _setOperation(buttonText);
      } else if (_isScientificFunction(buttonText)) {
        _performScientificFunction(buttonText);
      } else if (buttonText == '±') {
        _toggleSign();
      } else if (buttonText == '.') {
        _addDecimal();
      } else {
        _addDigit(buttonText);
      }
    });
  }

  void _clear() {
    display = '0';
    equation = '';
    result = 0;
    operation = '';
    operand = 0;
    shouldResetDisplay = false;
  }

  void _clearEntry() {
    display = '0';
    shouldResetDisplay = false;
  }

  void _backspace() {
    if (display.length > 1) {
      display = display.substring(0, display.length - 1);
    } else {
      display = '0';
    }
  }

  void _addDigit(String digit) {
    if (shouldResetDisplay) {
      display = digit;
      shouldResetDisplay = false;
    } else {
      display = display == '0' ? digit : display + digit;
    }
  }

  void _addDecimal() {
    if (shouldResetDisplay) {
      display = '0.';
      shouldResetDisplay = false;
    } else if (!display.contains('.')) {
      display = '$display.';
    }
  }

  void _toggleSign() {
    if (display != '0') {
      if (display.startsWith('-')) {
        display = display.substring(1);
      } else {
        display = '-$display';
      }
    }
  }

  bool _isOperator(String text) {
    return ['+', '-', '×', '÷', '%', '^'].contains(text);
  }

  bool _isScientificFunction(String text) {
    return ['sin', 'cos', 'tan', 'ln', 'log', '√', 'x²', '1/x'].contains(text);
  }

  void _setOperation(String op) {
    if (operation.isNotEmpty) {
      _calculate();
    }

    operand = double.parse(display);
    operation = op;
    equation = '$display $op';
    shouldResetDisplay = true;
  }

  void _calculate() {
    if (operation.isEmpty) return;

    double currentValue = double.parse(display);

    switch (operation) {
      case '+':
        result = operand + currentValue;
        break;
      case '-':
        result = operand - currentValue;
        break;
      case '×':
        result = operand * currentValue;
        break;
      case '÷':
        if (currentValue != 0) {
          result = operand / currentValue;
        } else {
          display = 'Error';
          return;
        }
        break;
      case '%':
        result = operand % currentValue;
        break;
      case '^':
        result = math.pow(operand, currentValue).toDouble();
        break;
    }

    String historyEntry =
        '$operand $operation $currentValue = ${_formatResult(result)}';
    history.insert(0, historyEntry);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    display = _formatResult(result);
    equation = '';
    operation = '';
    shouldResetDisplay = true;
  }

  void _performScientificFunction(String function) {
    double value = double.parse(display);

    switch (function) {
      case 'sin':
        result = math.sin(value * math.pi / 180);
        break;
      case 'cos':
        result = math.cos(value * math.pi / 180);
        break;
      case 'tan':
        result = math.tan(value * math.pi / 180);
        break;
      case 'ln':
        if (value > 0) {
          result = math.log(value);
        } else {
          display = 'Error';
          return;
        }
        break;
      case 'log':
        if (value > 0) {
          result = math.log(value) / math.log(10);
        } else {
          display = 'Error';
          return;
        }
        break;
      case '√':
        if (value >= 0) {
          result = math.sqrt(value);
        } else {
          display = 'Error';
          return;
        }
        break;
      case 'x²':
        result = value * value;
        break;
      case '1/x':
        if (value != 0) {
          result = 1 / value;
        } else {
          display = 'Error';
          return;
        }
        break;
    }

    String historyEntry = '$function($value) = ${_formatResult(result)}';
    history.insert(0, historyEntry);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }

    display = _formatResult(result);
    shouldResetDisplay = true;
  }

  String _formatResult(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      String formatted = value.toStringAsFixed(10);
      formatted = formatted.replaceAll(RegExp(r'0*$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
      return formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGradientStart, primaryGradientEnd],
            ),
          ),
        ),
        title: const Text(
          'Calculator',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isScientificMode ? Icons.calculate_rounded : Icons.functions,
                  size: 22,
                  color: textPrimary,
                ),
              ),
              onPressed: () {
                setState(() {
                  isScientificMode = !isScientificMode;
                });
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 22,
                  color: textPrimary,
                ),
              ),
              onPressed: () => _showHistory(),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1a1a1a),
              backgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100), // Account for app bar

            // Display Area
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (equation.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        equation,
                        style: TextStyle(
                          fontSize: 20,
                          color: textSecondary.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: display.length > 8 ? 42 : 56,
                      fontWeight: FontWeight.w200,
                      color: textPrimary,
                      letterSpacing: -2,
                      height: 1.1,
                    ),
                    child: Text(
                      display,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Button Area
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: isScientificMode
                    ? _buildScientificLayout()
                    : _buildBasicLayout(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicLayout() {
    return Column(
      children: [
        _buildButtonRow(['C', 'CE', '⌫', '÷']),
        _buildButtonRow(['7', '8', '9', '×']),
        _buildButtonRow(['4', '5', '6', '-']),
        _buildButtonRow(['1', '2', '3', '+']),
        _buildButtonRow(['±', '0', '.', '=']),
      ],
    );
  }

  Widget _buildScientificLayout() {
    return Column(
      children: [
        _buildButtonRow(['C', 'CE', '⌫', '÷', '%']),
        _buildButtonRow(['sin', 'cos', 'tan', '×', '^']),
        _buildButtonRow(['ln', 'log', '√', '-', '1/x']),
        _buildButtonRow(['7', '8', '9', '+', 'x²']),
        _buildButtonRow(['4', '5', '6', '1', '2']),
        _buildButtonRow(['3', '±', '0', '.', '=']),
      ],
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => _buildButton(button)).toList(),
      ),
    );
  }

  Widget _buildButton(String text) {
    ButtonStyle buttonStyle = _getButtonStyle(text);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onButtonPressed(text),
            borderRadius: BorderRadius.circular(24),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 - (_animationController.value * 0.05),
                  child: Container(
                    height: 75,
                    decoration: BoxDecoration(
                      gradient: buttonStyle.gradient,
                      color: buttonStyle.color,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: (buttonStyle.shadowColor ?? Colors.black)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: _getFontSize(text),
                        fontWeight: FontWeight.w600,
                        color: buttonStyle.textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getFontSize(String text) {
    if (text.length > 3) return 16;
    if (text.length > 2) return 18;
    return 24;
  }

  ButtonStyle _getButtonStyle(String text) {
    if (text == '=') {
      return ButtonStyle(
        gradient: const LinearGradient(
          colors: [accentGreen, Color(0xFF40c057)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textColor: textPrimary,
        shadowColor: accentGreen,
      );
    } else if (text == '+' || text == '-' || text == '×' || text == '÷') {
      return ButtonStyle(
        gradient: const LinearGradient(
          colors: [operatorColor, Color(0xFF3b5bdb)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textColor: textPrimary,
        shadowColor: operatorColor,
      );
    } else if (text == 'C' || text == 'CE' || text == '⌫') {
      return ButtonStyle(
        gradient: const LinearGradient(
          colors: [accentOrange, Color(0xFFfa5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textColor: textPrimary,
        shadowColor: accentOrange,
      );
    } else if (_isScientificFunction(text) || text == '%' || text == '^') {
      return ButtonStyle(
        gradient: const LinearGradient(
          colors: [secondaryGradientStart, secondaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        textColor: textPrimary,
        shadowColor: secondaryGradientStart,
      );
    } else {
      return ButtonStyle(
        color: surfaceVariant,
        textColor: textPrimary,
        shadowColor: Colors.black,
      );
    }
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: Colors.white12, width: 1),
            left: BorderSide(color: Colors.white12, width: 1),
            right: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 12),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [accentOrange, Color(0xFFfa5252)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          history.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // History List
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: surfaceVariant.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: textSecondary.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No calculations yet',
                            style: TextStyle(
                              fontSize: 20,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                String result = history[index].split('= ')[1];
                                setState(() {
                                  display = result;
                                  shouldResetDisplay = true;
                                });
                                Navigator.pop(context);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  history[index],
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 18,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonStyle {
  final Color? color;
  final Gradient? gradient;
  final Color textColor;
  final Color? shadowColor;

  ButtonStyle({
    this.color,
    this.gradient,
    required this.textColor,
    this.shadowColor,
  });
}
