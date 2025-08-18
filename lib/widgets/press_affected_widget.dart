import 'package:flutter/material.dart';

class CustomPressEffectWidget extends StatefulWidget {
  final Widget child;
  final Color backgroundColor;
  final Color? shadowColor;
  final bool isPressed;
  final VoidCallback? onTap;
  final Animation<double>? shakeAnimation;
  final Animation<double>? buttonPressAnimation;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double elevation;
  final double pressedElevation;

  const CustomPressEffectWidget({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.shadowColor,
    required this.isPressed,
    this.onTap,
    this.shakeAnimation,
    this.buttonPressAnimation,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.elevation = 8,
    this.pressedElevation = 2,
  });

  @override
  State<CustomPressEffectWidget> createState() =>
      _CustomPressEffectWidgetState();
}

class _CustomPressEffectWidgetState extends State<CustomPressEffectWidget> {
  bool _isLocalPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveShadowColor =
        widget.shadowColor ?? widget.backgroundColor.withOpacity(0.3);
    final currentElevation = (widget.isPressed || _isLocalPressed)
        ? widget.pressedElevation
        : widget.elevation;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: widget.margin,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: effectiveShadowColor,
              blurRadius: 0,
              offset: Offset(0, currentElevation),
            ),
            if (!(widget.isPressed || _isLocalPressed))
              BoxShadow(
                color: effectiveShadowColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: widget.onTap != null
                ? (_) => setState(() => _isLocalPressed = true)
                : null,
            onTapUp: widget.onTap != null
                ? (_) => setState(() => _isLocalPressed = false)
                : null,
            onTapCancel: widget.onTap != null
                ? () => setState(() => _isLocalPressed = false)
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    // Apply button press animation if provided
    if (widget.buttonPressAnimation != null) {
      content = AnimatedBuilder(
        animation: widget.buttonPressAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              (widget.isPressed || _isLocalPressed)
                  ? widget.buttonPressAnimation!.value
                  : 0,
            ),
            child: child,
          );
        },
        child: content,
      );
    }

    // Apply shake animation if provided
    if (widget.shakeAnimation != null) {
      content = AnimatedBuilder(
        animation: widget.shakeAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(widget.shakeAnimation!.value, 0),
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }
}

// Example Usage Widget
class ExampleUsage extends StatefulWidget {
  const ExampleUsage({super.key});

  @override
  _ExampleUsageState createState() => _ExampleUsageState();
}

class _ExampleUsageState extends State<ExampleUsage>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pressController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pressAnimation = Tween<double>(
      begin: 0,
      end: 4,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward().then((_) => _shakeController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Press Effect Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Blue card example
            CustomPressEffectWidget(
              backgroundColor: const Color(0xFF1CB0F6),
              shadowColor: const Color(0xFF1CB0F6).withOpacity(0.3),
              isPressed: false,
              onTap: () => ('Blue card tapped'),
              buttonPressAnimation: _pressAnimation,
              child: const Row(
                children: [
                  Icon(Icons.info, color: Colors.white, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Information Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Green card example
            CustomPressEffectWidget(
              backgroundColor: const Color(0xFF58CC02),
              shadowColor: const Color(0xFF58CC02).withOpacity(0.3),
              isPressed: false,
              onTap: () => ('Green card tapped'),
              buttonPressAnimation: _pressAnimation,
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Success Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Purple card with shake animation
            CustomPressEffectWidget(
              backgroundColor: const Color(0xFF9C27B0),
              shadowColor: const Color(0xFF9C27B0).withOpacity(0.3),
              isPressed: false,
              onTap: _triggerShake,
              shakeAnimation: _shakeAnimation,
              buttonPressAnimation: _pressAnimation,
              child: const Row(
                children: [
                  Icon(Icons.vibration, color: Colors.white, size: 24),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tap to Shake',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Custom styled card
            CustomPressEffectWidget(
              backgroundColor: Colors.white,
              shadowColor: Colors.black12,
              isPressed: false,
              borderRadius: 12,
              elevation: 4,
              pressedElevation: 1,
              onTap: () => ('Custom card tapped'),
              buttonPressAnimation: _pressAnimation,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Color(0xFF777777)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Custom Styled Card',
                      style: TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
