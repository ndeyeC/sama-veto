import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_service.dart';

/// Espace de l'utilisateur connecté (provisoire).
/// Charge le profil depuis l'API : c'est ce qui permet la reconnexion
/// automatique. Les interfaces propres à chaque rôle viendront ici.
class EspacePage extends StatefulWidget {
  const EspacePage({super.key});

  @override
  State<EspacePage> createState() => _EspacePageState();
}

class _EspacePageState extends State<EspacePage> {
  final _api = ApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getProfile();
  }

  void _goHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _logout() async {
    try {
      await _api.logout();
    } on ApiException catch (_) {
      // Le token local est supprimé dans tous les cas.
    }
    if (!mounted) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
        title: const Text('Sama Veto'),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Déconnexion'),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = snapshot.error;
          if (error != null) {
            // Session expirée ou token invalide : retour à l'accueil.
            if (error is ApiException && error.statusCode == 401) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _goHome();
              });
              return const SizedBox.shrink();
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is ApiException
                          ? error.message
                          : 'Impossible de charger votre espace.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _future = _api.getProfile()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = snapshot.data!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour ${user['name']}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text('Profil : ${user['role_label'] ?? '—'}'),
                      Text('Téléphone : ${user['phone'] ?? '—'}'),
                      Text('Région : ${user['region'] ?? '—'}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Votre espace personnalisé arrive bientôt.',
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
