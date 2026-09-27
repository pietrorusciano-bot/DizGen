import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api_service.dart';
import '../gen_style.dart';
import '../models.dart';
import 'word_detail_screen.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Term> _terms = [];
  List<Term> _filtered = [];
  final Map<String, int> _letterIndex = {};
  List<Generation> _generations = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  final Set<String> _selected = {};

  String? _dragLetter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final terms = await ApiService.instance.terms();
      terms.sort((a, b) => a.term.compareTo(b.term));
      final generations = await ApiService.instance.generations();
      generations.sort((a, b) => b.startYear.compareTo(a.startYear));
      if (!mounted) return;
      setState(() {
        _terms = terms;
        _generations = generations;
      });
      _recomputeFiltered();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recomputeFiltered() {
    final q = _query.toLowerCase();
    _filtered = _terms.where((t) {
      final matchesQuery = q.isEmpty ||
          t.term.toLowerCase().contains(q) ||
          t.definition.toLowerCase().contains(q);
      final matchesGen = _selected.isEmpty ||
          t.usingGenerations.any((g) => _selected.contains(g));
      return matchesQuery && matchesGen;
    }).toList();

    _letterIndex.clear();
    for (int i = 0; i < _filtered.length; i++) {
      _letterIndex.putIfAbsent(_letterOf(_filtered[i].term), () => i);
    }
  }

  int _countFor(String? key) {
    if (key == null) return _terms.length;
    return _terms.where((t) => t.usingGenerations.contains(key)).length;
  }

  String _letterOf(String s) {
    if (s.isEmpty) return '#';
    final code = s[0].toUpperCase().codeUnitAt(0);
    return (code >= 65 && code <= 90) ? String.fromCharCode(code) : '#';
  }

  double _thumbHeight(double trackH) {
    if (!_scrollController.hasClients) return 48;
    final pos = _scrollController.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return trackH;
    final content = max + pos.viewportDimension;
    return (pos.viewportDimension / content * trackH).clamp(48.0, trackH);
  }

  double _thumbTop(double trackH) {
    if (!_scrollController.hasClients) return 0;
    final pos = _scrollController.position;
    final max = pos.maxScrollExtent;
    if (max <= 0) return 0;
    final track = trackH - _thumbHeight(trackH);
    return (pos.pixels / max * track).clamp(0.0, track);
  }

  void _onDrag(double dy, double trackH) {
    if (!_scrollController.hasClients || _filtered.isEmpty) return;
    final max = _scrollController.position.maxScrollExtent;
    final fraction = (dy / trackH).clamp(0.0, 1.0);
    _scrollController.jumpTo(fraction * max);
    final idx =
        (fraction * (_filtered.length - 1)).round().clamp(0, _filtered.length - 1);
    final letter = _letterOf(_filtered[idx].term);
    if (_dragLetter != letter) setState(() => _dragLetter = letter);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _searchBar(),
        ),
        const SizedBox(height: 10),
        _generationPills(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final trackH = constraints.maxHeight;
                        return Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 28, 16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) =>
                                  _wordCard(_filtered[i]),
                            ),
                            Positioned(
                              right: 2,
                              top: 0,
                              bottom: 0,
                              child: _scrollbar(trackH),
                            ),
                            if (_dragLetter != null)
                              Positioned(
                                right: 26,
                                top: (_thumbTop(trackH) +
                                        _thumbHeight(trackH) / 2 -
                                        20)
                                    .clamp(0.0, trackH - 44),
                                child: _letterBubble(_dragLetter!),
                              ),
                          ],
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _scrollbar(double trackH) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (d) => _onDrag(d.localPosition.dy, trackH),
      onVerticalDragUpdate: (d) => _onDrag(d.localPosition.dy, trackH),
      onVerticalDragEnd: (_) => setState(() => _dragLetter = null),
      onTapDown: (d) => _onDrag(d.localPosition.dy, trackH),
      onTapUp: (_) => setState(() => _dragLetter = null),
      child: SizedBox(
        width: 24,
        height: trackH,
        child: AnimatedBuilder(
          animation: _scrollController,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned(
                  top: _thumbTop(trackH),
                  left: 4,
                  child: Container(
                    width: 8,
                    height: _thumbHeight(trackH),
                    decoration: BoxDecoration(
                      color: _dragLetter != null
                          ? const Color(0xFF7C3AED)
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _letterBubble(String letter) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xDD7C3AED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        letter,
        style: GoogleFonts.fredoka(
          fontSize: 28,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      onChanged: (v) {
        setState(() => _query = v);
        _recomputeFiltered();
      },
      decoration: InputDecoration(
        hintText: 'Cerca slang, significato o contesto...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _query = '');
                  _recomputeFiltered();
                },
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _generationPills() {
    final pills = <Widget>[
      _pill('Tutte', null, _countFor(null), _selected.isEmpty),
      ..._generations.map((g) => _pill(
            genName(g.key),
            g.key,
            _countFor(g.key),
            _selected.contains(g.key),
            color: genColor(g.key),
          )),
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: pills,
      ),
    );
  }

  Widget _pill(String label, String? key, int count, bool active,
      {Color? color}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (key == null) {
            _selected.clear();
          } else {
            if (_selected.contains(key)) {
              _selected.remove(key);
            } else {
              _selected.add(key);
            }
          }
        });
        _recomputeFiltered();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active
              ? (key == null ? const Color(0xFFFBBF24) : color)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Colors.transparent
                : (color ?? Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            if (key != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active
                    ? (key == null ? Colors.black : Colors.white)
                    : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active
                    ? (key == null ? Colors.black54 : Colors.white70)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wordCard(Term term) {
    final primaryGen = term.usingGenerations.isNotEmpty
        ? term.usingGenerations.first
        : null;
    final color = primaryGen != null ? genColor(primaryGen) : Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WordDetailScreen(term: term),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: genSoftColor(primaryGen ?? ''),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    term.usingGenerations.map(genName).join(' / '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              term.term,
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              term.definition,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.4,
                color: const Color(0xFF475569),
              ),
            ),
            if (term.example.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(color: color, width: 3),
                  ),
                ),
                child: Text(
                  '«${term.example}»',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
