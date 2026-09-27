import 'package:flutter_test/flutter_test.dart';

import 'package:dizgen/models.dart';

void main() {
  test('Generation parses from JSON', () {
    final gen = Generation.fromJson({
      'id': 1,
      'key': 'genz',
      'name': 'Generazione Z',
      'start_year': 1997,
      'end_year': 2012,
    });
    expect(gen.key, 'genz');
    expect(gen.name, 'Generazione Z');
    expect(gen.startYear, 1997);
  });

  test('TermMatch parses from JSON', () {
    final match = TermMatch.fromJson({
      'term': 'rizz',
      'definition': 'Carisma',
      'example': 'Ha un rizz incredibile',
      'familiar': false,
    });
    expect(match.term, 'rizz');
    expect(match.familiar, false);
  });
}
