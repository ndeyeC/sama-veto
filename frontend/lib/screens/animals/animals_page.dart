import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import 'animal_detail_page.dart';
import 'animal_form_page.dart';
import 'animal_widgets.dart';

/// Onglet « Animaux » (cahier des charges §3.3) : 3 compteurs, liste des fiches
/// avec barre de santé et badge de statut, bouton « + Ajouter un animal ».
/// Fonctionne hors ligne grâce au cache d'AnimalService.
class AnimalsPage extends StatefulWidget {
  const AnimalsPage({super.key});

  @override
  State<AnimalsPage> createState() => _AnimalsPageState();
}

class _AnimalsPageState extends State<AnimalsPage> {
  final _service = AnimalService();
  final _rechercheCtrl = TextEditingController();

  ListeAnimaux? _liste;
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
    _rechercheCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final liste = await _service.lister();
      if (mounted) setState(() => _liste = liste);
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  /// Recherche et filtre faits sur l'appareil : marchent aussi hors ligne.
  List<Animal> get _animauxFiltres {
    final terme = _rechercheCtrl.text.trim().toLowerCase();
    return (_liste?.animaux ?? []).where((a) {
      if (_especeFiltre != null && a.espece != _especeFiltre) return false;
      if (terme.isEmpty) return true;
      return [a.nom, a.race, a.numeroIdentification]
          .any((v) => v != null && v.toLowerCase().contains(terme));
    }).toList();
  }

  Future<void> _ajouter() async {
    final animal = await Navigator.of(context).push<Animal>(
      MaterialPageRoute(builder: (_) => const AnimalFormPage()),
    );
    if (animal == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(animal.enAttente
          ? '${animal.nom} est enregistré sur l’appareil. Il sera envoyé dès le retour de la connexion.'
          : '${animal.nom} a été ajouté.'),
    ));
    _charger();
  }

  Future<void> _ouvrir(Animal animal) async {
    final modifie = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AnimalDetailPage(animal: animal)),
    );
    if (modifie == true) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final nonConnecte = _erreur?.nonConnecte ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes animaux')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: nonConnecte ? _vueNonConnecte() : _vuePrincipale(),
        ),
      ),
      bottomNavigationBar: nonConnecte
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: _ajouter,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un animal'),
                ),
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
    final liste = _liste;
    final animaux = _animauxFiltres;

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (liste != null && liste.horsLigne) const BandeauHorsLigne(),
          if (liste != null && liste.enAttente > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '⏳ ${liste.enAttente} animal(aux) en attente de synchronisation',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
          if (liste != null)
            Row(
              children: [
                Expanded(child: Compteur(valeur: liste.total, label: 'Animaux', couleur: AppColors.green)),
                const SizedBox(width: 10),
                Expanded(child: Compteur(valeur: liste.aPlanifier, label: 'À planifier', couleur: couleurBientot)),
                const SizedBox(width: 10),
                Expanded(child: Compteur(valeur: liste.urgences, label: 'Urgences', couleur: couleurUrgent)),
              ],
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _rechercheCtrl,
            onChanged: (_) => setState(() {}),
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
                for (final e in Animal.especes.entries) _filtre(e.key, '${e.value.$1} ${e.value.$2}'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_chargement && liste == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_erreur != null)
            MessageVide(
              icon: Icons.error_outline,
              texte: _erreur!.message,
              action: TextButton(onPressed: _charger, child: const Text('Réessayer')),
            )
          else if (animaux.isEmpty)
            MessageVide(
              icon: Icons.pets,
              texte: (liste?.total ?? 0) == 0
                  ? 'Aucun animal pour le moment.\nAppuyez sur « Ajouter un animal » pour commencer.'
                  : 'Aucun animal ne correspond à votre recherche.',
            )
          else
            for (final a in animaux) CarteAnimal(animal: a, onTap: () => _ouvrir(a)),
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
        onSelected: (_) => setState(() => _especeFiltre = espece),
      ),
    );
  }
}
