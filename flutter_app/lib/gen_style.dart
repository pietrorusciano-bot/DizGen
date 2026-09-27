import 'package:flutter/material.dart';

const genColorMap = {
  'genz': Color(0xFF7C3AED),
  'genalpha': Color(0xFFDB2777),
  'millennials': Color(0xFFEA580C),
  'boomers': Color(0xFF059669),
  'genx': Color(0xFF2563EB),
};

const genSoftColorMap = {
  'genz': Color(0xFFF3E8FF),
  'genalpha': Color(0xFFFCE7F3),
  'millennials': Color(0xFFFFEDD5),
  'boomers': Color(0xFFD1FAE5),
  'genx': Color(0xFFDBEAFE),
};

Color genColor(String key) => genColorMap[key] ?? const Color(0xFF64748B);

Color genSoftColor(String key) =>
    genSoftColorMap[key] ?? const Color(0xFFF1F5F9);

const genNameMap = {
  'boomers': 'Boomers',
  'genx': 'Gen X',
  'millennials': 'Millennials',
  'genz': 'Gen Z',
  'genalpha': 'Gen Alpha',
};

String genName(String key) => genNameMap[key] ?? key;

String avatarAsset(String? genKey, String? gender) {
  if (gender == null) {
    return 'assets/avatars/male_default.png';
  }
  final prefix = gender == 'female' ? 'female' : 'male';
  final gen = switch (genKey) {
    'boomers' => 'boomers',
    'genx' => 'genx',
    'millennials' => 'millennials',
    'genz' => 'genz',
    _ => 'default',
  };
  return 'assets/avatars/${prefix}_$gen.png';
}
