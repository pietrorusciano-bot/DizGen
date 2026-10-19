import '../models.dart';

const Map<String, String> _accentMap = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

String normalizeText(String text) {
  final lowered = text.toLowerCase();
  final sb = StringBuffer();
  for (final ch in lowered.split('')) {
    sb.write(_accentMap[ch] ?? ch);
  }
  return sb.toString();
}

RegExp _regexFor(String normalizedTerm) {
  final words = normalizedTerm
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => RegExp.escape(w))
      .toList();
  final joined = words.join(r'\s+');
  return RegExp('\\b$joined\\b');
}

List<Term> findMatches(String text, List<Term> terms) {
  final normalizedText = normalizeText(text);
  final found = <(Term, int, int)>[];

  for (final term in terms) {
    final normalized = normalizeText(term.term);
    final pattern = _regexFor(normalized);
    for (final m in pattern.allMatches(normalizedText)) {
      found.add((term, m.start, m.end));
    }
  }

  found.sort((a, b) {
    final cmp = (b.$3 - b.$2).compareTo(a.$3 - a.$2);
    return cmp;
  });

  final kept = <Term>[];
  final occupied = <(int, int)>[];
  for (final (term, start, end) in found) {
    var overlap = false;
    for (final (oStart, oEnd) in occupied) {
      if (start < oEnd && end > oStart) {
        overlap = true;
        break;
      }
    }
    if (!overlap) {
      kept.add(term);
      occupied.add((start, end));
    }
  }

  return kept;
}
