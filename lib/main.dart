import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Palette
    const Color accent = Color(0xFFC8860A);
    const Color bg = Color(0xFF0F1923);

    return MaterialApp(
      title: 'CGuard Pro',
      theme: ThemeData(
        primaryColor: accent,
        scaffoldBackgroundColor: bg,
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: accent, width: 2.0),
          ),
          labelStyle: const TextStyle(color: Color(0xFF0F1923)),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accent),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: accent),
        ),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _loading = false;
          _user = null;
        });
        return;
      }

      // Validate token by calling /auth/me
      final resp = await ApiService.get('/auth/me');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _user = body as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        // invalid token -> sign out
        await AuthService.signOut();
        setState(() {
          _user = null;
          _loading = false;
        });
      }
    } catch (e) {
      // On error, assume not authenticated
      await AuthService.signOut();
      setState(() {
        _user = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user != null) {
      return HomeScreen(user: _user);
    }

    return const SignInScreen();
  }
}
