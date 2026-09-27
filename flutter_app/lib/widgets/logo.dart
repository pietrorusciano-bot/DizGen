import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GeneraTalkLogo extends StatelessWidget {
  final double fontSize;
  final Color dark;
  final Color accent;
  final FontWeight weight;

  const GeneraTalkLogo({
    super.key,
    this.fontSize = 32,
    this.dark = Colors.white,
    this.accent = const Color(0xFFFACC15),
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.fredoka(
          fontSize: fontSize,
          fontWeight: weight,
        ),
        children: [
          TextSpan(text: 'Genera', style: TextStyle(color: dark)),
          TextSpan(text: 'Talk', style: TextStyle(color: accent)),
        ],
      ),
    );
  }
}
