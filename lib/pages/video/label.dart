import 'package:flutter/material.dart';

class MyLabelWidget extends StatelessWidget {
  const MyLabelWidget({
    Key? key,
    this.fontSize,
    this.color,
    this.padding,
    required this.label,
    this.onTab,
  }) : super(key: key);
  final double? fontSize;
  final String label;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTab;
  @override
  Widget build(BuildContext context) {
    return onTab != null
        ? GestureDetector(
            onTap: onTab,
            child: _buildBox(context),
          )
        : _buildBox(context);
  }

  Widget _buildBox(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.copyWith(
          fontSize: fontSize ?? 36.0,
          color: color ?? Colors.white,
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB8000000),
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          label,
          style: style,
        ),
      ),
    );
  }
}

class MyIconWidget extends StatelessWidget {
  const MyIconWidget({
    Key? key,
    this.fontSize,
    this.color,
    this.padding,
    required this.icon,
    this.onTab,
  }) : super(key: key);
  final double? fontSize;
  final IconData icon;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTab;
  @override
  Widget build(BuildContext context) {
    return onTab != null
        ? GestureDetector(
            onTap: onTab,
            child: _buildBox(context),
          )
        : _buildBox(context);
  }

  Widget _buildBox(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xB8000000),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Icon(
            icon,
            size: fontSize ?? 36.0,
            color: color ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
