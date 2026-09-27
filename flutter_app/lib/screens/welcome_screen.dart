import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/logo.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1022),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const GeneraTalkLogo(
                fontSize: 48,
                dark: Colors.white,
                accent: Color(0xFFFACC15),
                weight: FontWeight.w800,
              ),
              const SizedBox(height: 14),
              Text(
                'Le parole cambiano,\nle generazioni anche.\nTu ascolti, noi ti spieghiamo.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              _bubblesRow(),
              const SizedBox(height: 6),
              _characters(),
              const Spacer(),
              _startButton(context),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubblesRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Transform.rotate(
          angle: -0.2,
          child: _bubble('cringe', const Color(0xFF8B5CF6)),
        ),
        _vsBadge(),
        Transform.rotate(
          angle: 0.2,
          child: _bubble('boomer', const Color(0xFF10B981)),
        ),
      ],
    );
  }

  Widget _bubble(String word, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 18),
        ],
      ),
      child: Text(
        word,
        style: GoogleFonts.fredoka(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _vsBadge() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFFACC15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          'VS',
          style: GoogleFonts.fredoka(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _characters() {
    return Row(
      children: [
        Expanded(
          child: _character('🧑‍🎤', const Color(0xFF6D28D9), 'Gen Z'),
        ),
        Expanded(
          child: _character('👵', const Color(0xFF047857), 'Boomer'),
        ),
      ],
    );
  }

  Widget _character(String emoji, Color color, String label) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 56)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _startButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFED02F),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 8,
        ),
        child: Text(
          'Inizia',
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
