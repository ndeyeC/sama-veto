import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'espace_page.dart';
import 'home_page.dart';

/// Point d'entrée de l'app : si une session existe, on ouvre directement
/// l'espace de l'utilisateur ; sinon, la page d'accueil.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _loggedIn = ApiService().isLoggedIn();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == true ? const EspacePage() : const HomePage();
      },
    );
  }
}
