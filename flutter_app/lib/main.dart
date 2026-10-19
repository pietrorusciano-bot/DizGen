import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api_service.dart';
import 'data/app_database.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GeneraTalkApp());
}

class GeneraTalkApp extends StatelessWidget {
  const GeneraTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeneraTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF7C3AED),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ApiService.instance.authState.addListener(_onAuthChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    ApiService.instance.authState.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    await AppDatabase.instance.initialize();
    await ApiService.instance.loadSession();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C1022),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final hasUser = ApiService.instance.user != null;
    return hasUser ? const HomeScreen() : const WelcomeScreen();
  }
}
