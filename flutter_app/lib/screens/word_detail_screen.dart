import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api_service.dart';
import '../gen_style.dart';
import '../models.dart';

class WordDetailScreen extends StatefulWidget {
  final Term term;
  const WordDetailScreen({super.key, required this.term});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  @override
  void initState() {
    super.initState();
    ApiService.instance.markDiscovered(widget.term.id).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final generations = term.usingGenerations;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Significato',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(child: _wordSplash(term.term)),
          const SizedBox(height: 20),
          Text(
            term.definition,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              height: 1.5,
              color: const Color(0xFF1E293B),
            ),
          ),
          if (term.example.isNotEmpty) ...[
            const SizedBox(height: 20),
            _exampleBox(term.example),
          ],
          const SizedBox(height: 24),
          _generationsSection(generations),
          const SizedBox(height: 28),
          _discoveredButton(),
        ],
      ),
    );
  }

  Widget _wordSplash(String word) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6524D6), Color(0xFF8B3CF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        word.toLowerCase(),
        style: GoogleFonts.fredoka(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _exampleBox(String example) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5D9FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFF1E293B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'In pratica...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  example,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFF1E293B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _generationsSection(List<String> generations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usato da',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: generations.map((key) {
            final color = genColor(key);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                genName(key),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _discoveredButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Parola aggiunta alle scoperte')),
          );
        },
        icon: const Icon(Icons.star, color: Color(0xFFFBBF24)),
        label: const Text('Aggiungi ai preferiti'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E293B)),
      ),
    );
  }
}
