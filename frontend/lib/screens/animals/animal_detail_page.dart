import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import 'animal_form_page.dart';
import 'animal_widgets.dart';

/// Carnet de santé d'un animal (cahier des charges §3.3) : grand emoji, nom,
/// race · sexe · naissance, historique de santé, bouton rouge « Supprimer ».
/// Renvoie `true` à la liste si l'animal a été modifié ou supprimé.
class AnimalDetailPage extends StatefulWidget {
  const AnimalDetailPage({required this.animal, super.key});

  final Animal animal;

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  final _service = AnimalService();
  late Animal _animal = widget.animal;
  bool _modifie = false;

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _marquerFait(HealthEvent e) async {
    if (_animal.enAttente || e.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acte réalisé ?'),
        content: Text('Marquer « ${e.acte} » comme fait aujourd’hui ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oui, c’est fait')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final maj = await _service.marquerFait(_animal.id!, e.id!);
      setState(() {
        _animal = maj;
        _modifie = true;
      });
    } on ApiException catch (err) {
      if (mounted) _message(err.horsLigne ? 'Connexion nécessaire pour mettre à jour le carnet.' : err.message);
    }
  }

  Future<void> _modifier() async {
    final maj = await Navigator.of(context).push<Animal>(
      MaterialPageRoute(builder: (_) => AnimalFormPage(animal: _animal)),
    );
    if (maj != null) {
      setState(() {
        _animal = maj;
        _modifie = true;
      });
    }
  }

  Future<void> _supprimer() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cet animal ?'),
        content: Text(
          '« ${_animal.nom} » et tout son carnet de santé seront définitivement supprimés. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: couleurUrgent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.supprimer(_animal);
      if (!mounted) return;
      _message('${_animal.nom} a été supprimé.');
      Navigator.of(context).pop(true);
    } on ApiException catch (err) {
      if (mounted) _message(err.horsLigne ? 'Connexion nécessaire pour supprimer un animal.' : err.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _animal;
    final infos = [
      if (a.race != null && a.race!.isNotEmpty) a.race!,
      a.sexeLabel,
      if (a.naissanceLabel != null) 'né(e) en ${a.naissanceLabel}',
    ].join(' · ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_modifie);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carnet de santé'),
          actions: [
            if (!a.enAttente)
              IconButton(tooltip: 'Modifier', onPressed: _modifier, icon: const Icon(Icons.edit_outlined)),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(child: Text(a.emoji, style: const TextStyle(fontSize: 72))),
                const SizedBox(height: 8),
                Text(
                  a.nom,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                ),
                const SizedBox(height: 4),
                Text(infos, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText)),
                const SizedBox(height: 12),
                Center(child: BadgeStatut(animal: a)),
                const SizedBox(height: 12),
                BarreSante(animal: a),
                if (a.numeroIdentification != null || a.poids != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    [
                      if (a.numeroIdentification != null) 'N° ${a.numeroIdentification}',
                      if (a.poids != null) '${a.poids} kg',
                      if (a.couleur != null) a.couleur!,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                const Text(
                  'Historique de santé',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
                ),
                if (!a.enAttente && a.evenements.any((e) => !e.fait))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Touchez un acte prévu pour le marquer comme fait.',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                for (final e in a.evenements) _LigneEvenement(evenement: e, onTap: () => _marquerFait(e)),
                if (a.evenements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun acte enregistré.', style: TextStyle(color: AppColors.mutedText)),
                  ),
                if (a.notes != null && a.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(a.notes!),
                ],
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: couleurUrgent),
                  onPressed: _supprimer,
                  icon: const Text('🗑'),
                  label: const Text('Supprimer cet animal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LigneEvenement extends StatelessWidget {
  const _LigneEvenement({required this.evenement, required this.onTap});

  final HealthEvent evenement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = evenement;
    final (icone, couleur, precision) = switch (e.statut) {
      'fait' => ('✓', couleurAJour, 'Fait le ${Animal.formatDateFr(e.dateRealisee ?? e.datePrevue)}'),
      'en_retard' => ('!', couleurBientot, 'En retard · prévu le ${Animal.formatDateFr(e.datePrevue)}'),
      'bientot' => ('⏰', couleurBientot, 'Bientôt · prévu le ${Animal.formatDateFr(e.datePrevue)}'),
      _ => ('•', AppColors.mutedText, 'Prévu le ${Animal.formatDateFr(e.datePrevue)}'),
    };

    return ListTile(
      onTap: e.fait ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: couleur.withValues(alpha: 0.12),
        child: Text(icone, style: TextStyle(color: couleur, fontWeight: FontWeight.w800)),
      ),
      title: Text(e.acte, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(precision, style: TextStyle(color: e.statut == 'en_retard' ? couleurBientot : null)),
    );
  }
}
