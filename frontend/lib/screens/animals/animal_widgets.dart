import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';

/// Widgets partagés par les écrans de l'onglet Animaux.

const couleurUrgent = Color(0xFFC62828);
const couleurBientot = Color(0xFFE67E22);
const couleurAJour = AppColors.green;

/// Indicateur « hors ligne » (règle 4 : statut réseau visible).
class BandeauHorsLigne extends StatelessWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5C27A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, color: couleurBientot, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text('Hors ligne : vous voyez les dernières données enregistrées sur l’appareil.'),
          ),
        ],
      ),
    );
  }
}

/// Un des 3 compteurs (total / à planifier / urgences).
class Compteur extends StatelessWidget {
  const Compteur({required this.valeur, required this.label, required this.couleur, super.key});

  final int valeur;
  final String label;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$valeur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: couleur)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
        ],
      ),
    );
  }
}

/// Badge ⚠ Urgent / ⏰ Bientôt / ✓ À jour (ou ⏳ en attente de synchronisation).
class BadgeStatut extends StatelessWidget {
  const BadgeStatut({required this.animal, super.key});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final (texte, couleur) = animal.enAttente
        ? ('⏳ À synchroniser', AppColors.mutedText)
        : switch (animal.statutSante) {
            'urgent' => ('⚠ Urgent', couleurUrgent),
            'bientot' => ('⏰ Bientôt', couleurBientot),
            _ => ('✓ À jour', couleurAJour),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texte, style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Barre de progression « % santé » (couverture vaccinale).
class BarreSante extends StatelessWidget {
  const BarreSante({required this.animal, super.key});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final couleur = switch (animal.statutSante) {
      'urgent' => couleurUrgent,
      'bientot' => couleurBientot,
      _ => couleurAJour,
    };
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: animal.couverture / 100,
              minHeight: 7,
              color: couleur,
              backgroundColor: AppColors.border,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${animal.couverture} %', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
      ],
    );
  }
}

/// Une fiche animal dans la liste.
class CarteAnimal extends StatelessWidget {
  const CarteAnimal({required this.animal, required this.onTap, super.key});

  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sousTitre = [
      if (animal.race != null && animal.race!.isNotEmpty) animal.race! else animal.especeLabel,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(animal.emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            animal.nom,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                        BadgeStatut(animal: animal),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(sousTitre, style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                    const SizedBox(height: 8),
                    BarreSante(animal: animal),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageVide extends StatelessWidget {
  const MessageVide({required this.icon, required this.texte, this.action, super.key});

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
