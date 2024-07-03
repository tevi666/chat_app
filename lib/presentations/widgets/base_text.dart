import 'package:flutter/material.dart';

class BaseText extends StatelessWidget {
  const BaseText({super.key, required this.text, this.color = Colors.white, this.fontSize = 30, this.fontFamily = 'Gilroy-B', this.textAlign = TextAlign.start});
  final String text;
  final Color color;
  final double fontSize;
  final String fontFamily;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(color: color, fontSize: fontSize, fontFamily: fontFamily), textAlign: textAlign,);
  }
}


