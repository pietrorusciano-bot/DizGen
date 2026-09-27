import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api_service.dart';
import '../gen_style.dart';
import '../models.dart';
import 'welcome_screen.dart';
import 'word_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Term> _discovered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final discovered = await ApiService.instance.discovered();
      if (mounted) setState(() => _discovered = discovered);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _deleteAccountButton() {
    return OutlinedButton.icon(
      onPressed: _confirmDeleteAccount,
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('Elimina account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina account'),
        content: const Text(
            'Vuoi eliminare definitivamente il tuo account? Questa operazione non può essere annullata.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.user;
    final username = user?.username ?? '...';
    final genKey = user?.generation?.key;
    final genNameLabel = genKey != null ? genName(genKey) : null;
    final gender = user?.gender;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(username, genNameLabel, genKey, gender),
          const SizedBox(height: 20),
          _statsCard(_discovered.length),
          const SizedBox(height: 24),
          _discoveredSection(),
          const SizedBox(height: 32),
          _deleteAccountButton(),
        ],
      ),
    );
  }

  Widget _header(
      String username, String? genNameLabel, String? genKey, String? gender) {
    return Row(
      children: [
        GestureDetector(
          onTap: _changeGender,
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: genKey != null ? genColor(genKey) : Colors.grey,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatarAsset(genKey, gender),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Modifica',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (genNameLabel != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: genKey != null
                        ? genColor(genKey)
                        : const Color(0xFF7C3AED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    genNameLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changeGender() async {
    final current = ApiService.instance.user?.gender;
    final genKey = ApiService.instance.user?.generation?.key ?? '';
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Scegli la foto profilo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: _avatarPreview(genKey, 'male'),
              title: const Text('Maschio'),
              trailing: current == 'male' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'male'),
            ),
            ListTile(
              leading: _avatarPreview(genKey, 'female'),
              title: const Text('Femmina'),
              trailing: current == 'female' ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, 'female'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (result == null || result == current) return;
    try {
      await ApiService.instance.updateGender(result);
      if (mounted) setState(() {});
    } catch (_) {
      // ignore
    }
  }

  Widget _avatarPreview(String genKey, String gender) {
    return ClipOval(
      child: Image.asset(
        avatarAsset(genKey, gender),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _statsCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(count.toString(), 'parole scoperte'),
          _stat('${_discovered.where((t) => t.usingGenerations.contains('genz')).length}',
              'da Gen Z'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.fredoka(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _discoveredSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Le tue parole scoperte',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_discovered.isEmpty)
          Text(
            'Ancora nessuna parola scoperta. Ascolta o apri il dizionario per iniziare!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          )
        else
          ..._discovered.map(_wordPill),
      ],
    );
  }

  Widget _wordPill(Term term) {
    final primaryGen = term.usingGenerations.isNotEmpty
        ? term.usingGenerations.first
        : null;
    final color = primaryGen != null ? genColor(primaryGen) : Colors.grey;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WordDetailScreen(term: term)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                term.term,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              term.usingGenerations.map(genName).join(', '),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
