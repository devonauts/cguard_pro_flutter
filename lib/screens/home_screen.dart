import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic>? user;
  const HomeScreen({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    final email = user != null && user!['email'] != null
        ? user!['email'].toString()
        : 'Usuario';
    return Scaffold(
      appBar: AppBar(title: const Text('CGuard Pro')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bienvenido, $email'),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                child: const Text('Cerrar sesión (volver)')),
          ],
        ),
      ),
    );
  }
}
