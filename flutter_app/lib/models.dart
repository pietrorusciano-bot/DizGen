class Generation {
  final int id;
  final String key;
  final String name;
  final int startYear;
  final int endYear;

  Generation({
    required this.id,
    required this.key,
    required this.name,
    required this.startYear,
    required this.endYear,
  });

  factory Generation.fromJson(Map<String, dynamic> json) => Generation(
        id: json['id'] as int,
        key: json['key'] as String,
        name: json['name'] as String,
        startYear: json['start_year'] as int,
        endYear: json['end_year'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'name': name,
        'start_year': startYear,
        'end_year': endYear,
      };
}

class User {
  final int id;
  final String username;
  final int birthYear;
  final String? gender;
  final Generation? generation;

  User({
    required this.id,
    required this.username,
    required this.birthYear,
    this.gender,
    this.generation,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        username: json['username'] as String,
        birthYear: json['birth_year'] as int,
        gender: json['gender'] as String?,
        generation: json['generation'] == null
            ? null
            : Generation.fromJson(json['generation'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'birth_year': birthYear,
        'gender': gender,
        'generation': generation?.toJson(),
      };
}

class Term {
  final int id;
  final String term;
  final String definition;
  final String example;
  final String source;
  final List<String> usingGenerations;

  Term({
    required this.id,
    required this.term,
    required this.definition,
    required this.example,
    required this.source,
    required this.usingGenerations,
  });

  factory Term.fromJson(Map<String, dynamic> json) => Term(
        id: json['id'] as int,
        term: json['term'] as String,
        definition: json['definition'] as String,
        example: json['example'] as String? ?? '',
        source: json['source'] as String? ?? '',
        usingGenerations: (json['generations'] as List<dynamic>)
            .map((g) => (g as Map<String, dynamic>)['key'] as String)
            .toList(),
      );
}

class TermMatch {
  final int id;
  final String term;
  final String definition;
  final String example;
  final bool familiar;
  final List<String> usingGenerations;

  TermMatch({
    required this.id,
    required this.term,
    required this.definition,
    required this.example,
    required this.familiar,
    required this.usingGenerations,
  });

  factory TermMatch.fromJson(Map<String, dynamic> json) => TermMatch(
        id: json['id'] as int,
        term: json['term'] as String,
        definition: json['definition'] as String,
        example: json['example'] as String? ?? '',
        familiar: json['familiar'] as bool,
        usingGenerations: (json['using_generations'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
      );
}
