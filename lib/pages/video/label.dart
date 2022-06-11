import 'package:flutter/material.dart';

class MyLabelWidget extends StatelessWidget {
  const MyLabelWidget({
    Key? key,
    this.fontSize,
    this.color,
    this.padding,
    required this.label,
  }) : super(key: key);
  final double? fontSize;
  final String label;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
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
