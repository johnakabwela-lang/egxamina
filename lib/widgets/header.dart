// custom_subject_app_bar.dart
import 'package:flutter/material.dart';

/// Custom AppBar that integrates seamlessly with SubjectHeader
class CustomSubjectAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final Color foregroundColor;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const CustomSubjectAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Reusable Subject Header Container
class SubjectHeader extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;
  final double borderRadius;

  const SubjectHeader({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    this.iconSize = 48,
    this.fontSize = 28,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Combined AppBar and Header for easy use
class SubjectAppBarWithHeader extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? leading;
  final double iconSize;
  final double fontSize;
  final EdgeInsets headerPadding;
  final double borderRadius;

  const SubjectAppBarWithHeader({
    super.key,
    required this.name,
    required this.color,
    required this.icon,
    this.actions,
    this.leading,
    this.iconSize = 48,
    this.fontSize = 28,
    this.headerPadding = const EdgeInsets.all(24),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomSubjectAppBar(
          title: name,
          backgroundColor: color,
          actions: actions,
          leading: leading,
        ),
        SubjectHeader(
          name: name,
          color: color,
          icon: icon,
          iconSize: iconSize,
          fontSize: fontSize,
          padding: headerPadding,
          borderRadius: borderRadius,
        ),
      ],
    );
  }
}
