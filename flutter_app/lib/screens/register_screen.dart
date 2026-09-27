import 'package:flutter/material.dart';

import '../api_service.dart';
import '../gen_style.dart';
import '../models.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  List<Generation> _generations = [];
  Generation? _selected;
  String? _gender;
  bool _loadingGenerations = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenerations();
  }

  Future<void> _loadGenerations() async {
    try {
      final list = await ApiService.instance.generations();
      if (!mounted) return;
      setState(() {
        _generations = list;
        _loadingGenerations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingGenerations = false;
      });
    }
  }

  Future<void> _register() async {
    if (_selected == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ApiService.instance.register(
        username: _username.text.trim(),
        password: _password.text,
        birthYear: _selected!.startYear,
        gender: _gender,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _avatarPreview() {
    final genKey = _selected?.key;
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: genKey != null ? genColor(genKey) : Colors.grey,
          width: 3,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          avatarAsset(genKey, _gender),
          width: 88,
          height: 88,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _genderOption(String value, String emoji, String label) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF3E8FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? const Color(0xFF7C3AED) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrati')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Sesso'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _genderOption('male', '👨', 'Maschio'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _genderOption('female', '👩', 'Femmina'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('A quale generazione appartieni?'),
                const SizedBox(height: 8),
                if (_loadingGenerations)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<Generation>(
                    initialValue: _selected,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Seleziona la tua fascia di età'),
                    items: _generations
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(
                                  '${g.name} (${g.startYear} - ${g.endYear})'),
                            ))
                        .toList(),
                    onChanged: (g) => setState(() => _selected = g),
                  ),
                const SizedBox(height: 20),
                Center(child: _avatarPreview()),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (_submitting || _selected == null) ? null : _register,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Crea account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
