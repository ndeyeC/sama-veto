import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import 'animal_form_page.dart';

/// Écran « Mes animaux » : liste, recherche, filtre par espèce, statistiques,
/// ajout / modification / suppression. Toutes les données viennent de l'API.
class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  final _service = AnimalService();
  final _rechercheCtrl = TextEditingController();
  Timer? _debounce;

  List<Animal> _animaux = [];
  Map<String, dynamic>? _stats;
  String? _especeFiltre;
  bool _chargement = true;
  ApiException? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final resultats = await Future.wait([
        _service.lister(espece: _especeFiltre, recherche: _rechercheCtrl.text),
        _service.statistiques(),
      ]);
      if (!mounted) return;
      setState(() {
        _animaux = resultats[0] as List<Animal>;
        _stats = resultats[1] as Map<String, dynamic>;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _onRecherche(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _charger);
  }

  Future<void> _ouvrirFormulaire([Animal? animal]) async {
    final modifie = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnimalFormPage(animal: animal)),
    );
    if (modifie == true) _charger();
  }

  Future<void> _supprimer(Animal animal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet animal ?'),
        content: Text('« ${animal.nom} » sera définitivement supprimé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.supprimer(animal.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${animal.nom} a été supprimé.')),
      );
      _charger();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _afficherDetails(Animal animal) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (ctx) => _AnimalDetails(
        animal: animal,
        onModifier: () {
          Navigator.pop(ctx);
          _ouvrirFormulaire(animal);
        },
        onSupprimer: () {
          Navigator.pop(ctx);
          _supprimer(animal);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonConnecte = _erreur?.nonConnecte ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes animaux')),
      floatingActionButton: nonConnecte
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _ouvrirFormulaire(),
              backgroundColor: AppColors.green,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un animal'),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: nonConnecte ? _vueNonConnecte() : _vuePrincipale(),
        ),
      ),
    );
  }

  Widget _vueNonConnecte() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 56, color: AppColors.mutedText),
          const SizedBox(height: 16),
          Text(_erreur!.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: const Text('Se connecter'),
          ),
          // TEMPORAIRE : visible seulement en mode debug, en attendant l'écran de connexion.
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.science_outlined),
              label: const Text('Tester avec le compte démo'),
              onPressed: () async {
                try {
                  await _service.connexionDemo();
                  _charger();
                } on ApiException catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _vuePrincipale() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          if (_stats != null) _StatsBar(stats: _stats!),
          const SizedBox(height: 16),
          TextField(
            controller: _rechercheCtrl,
            onChanged: _onRecherche,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, race ou numéro…',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filtre(null, 'Toutes'),
                for (final e in Animal.especes.entries) _filtre(e.key, e.value),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_chargement)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_erreur != null)
            _MessageVide(
              icon: Icons.cloud_off,
              texte: _erreur!.message,
              action: TextButton(onPressed: _charger, child: const Text('Réessayer')),
            )
          else if (_animaux.isEmpty)
            const _MessageVide(
              icon: Icons.pets,
              texte: 'Aucun animal pour le moment.\nAppuyez sur « Ajouter un animal » pour commencer.',
            )
          else
            for (final a in _animaux)
              _AnimalCard(animal: a, onTap: () => _afficherDetails(a)),
        ],
      ),
    );
  }

  Widget _filtre(String? espece, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _especeFiltre == espece,
        selectedColor: AppColors.lightGreen,
        onSelected: (_) {
          setState(() => _especeFiltre = espece);
          _charger();
        },
      ),
    );
  }
}

/// Icône par espèce.
IconData iconeEspece(String espece) => switch (espece) {
      'volaille' => Icons.egg_outlined,
      'chien' || 'chat' || 'autre' => Icons.pets,
      _ => Icons.agriculture_outlined,
    };

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final parEspece = (stats['par_espece'] is Map)
        ? Map<String, dynamic>.from(stats['par_espece'] as Map)
        : <String, dynamic>{};
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatTile(label: 'Total', valeur: '${stats['total'] ?? 0}', fort: true),
        for (final e in parEspece.entries)
          _StatTile(label: Animal.especes[e.key] ?? e.key, valeur: '${e.value}'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.valeur, this.fort = false});

  final String label;
  final String valeur;
  final bool fort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: fort ? AppColors.green : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fort ? AppColors.green : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: fort ? AppColors.white : AppColors.darkGreen,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: fort ? AppColors.lightGreen : AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.onTap});

  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sousTitre = [
      animal.especeLabel,
      if (animal.race != null && animal.race!.isNotEmpty) animal.race!,
      animal.sexeLabel,
      if (animal.age != null) animal.age!,
    ].join(' · ');

    return Card(
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.lightGreen,
          child: Icon(iconeEspece(animal.espece), color: AppColors.green),
        ),
        title: Text(
          animal.nom,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen),
        ),
        subtitle: Text(sousTitre, style: const TextStyle(color: AppColors.mutedText)),
        trailing: animal.numeroIdentification != null
            ? Text(animal.numeroIdentification!, style: const TextStyle(fontSize: 12))
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _AnimalDetails extends StatelessWidget {
  const _AnimalDetails({required this.animal, required this.onModifier, required this.onSupprimer});

  final Animal animal;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  @override
  Widget build(BuildContext context) {
    final lignes = <(String, String?)>[
      ('Espèce', animal.especeLabel),
      ('Race', animal.race),
      ('Sexe', animal.sexeLabel),
      (
        'Date de naissance',
        animal.dateNaissance != null
            ? '${Animal.formatDateFr(animal.dateNaissance!)} (${animal.age})'
            : null
      ),
      ('Poids', animal.poids != null ? '${animal.poids} kg' : null),
      ('Couleur', animal.couleur),
      ('N° d’identification', animal.numeroIdentification),
      ('Notes', animal.notes),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              animal.nom,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 12),
            for (final (label, valeur) in lignes)
              if (valeur != null && valeur.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(label, style: const TextStyle(color: AppColors.mutedText)),
                      ),
                      Expanded(child: Text(valeur)),
                    ],
                  ),
                ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSupprimer,
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                    label: Text('Supprimer', style: TextStyle(color: Colors.red.shade700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onModifier,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageVide extends StatelessWidget {
  const _MessageVide({required this.icon, required this.texte, this.action});

  final IconData icon;
  final String texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.mutedText),
          const SizedBox(height: 12),
          Text(texte, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
          if (action != null) action!,
        ],
      ),
    );
  }
}
