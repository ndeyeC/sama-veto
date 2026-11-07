import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';

/// Formulaire d'ajout (animal == null) ou de modification (cahier des charges §3.3) :
/// grille des 8 espèces, nom, race, sexe, mois et année de naissance.
/// Renvoie l'animal enregistré à l'écran précédent (ou null si annulé).
class AnimalFormPage extends StatefulWidget {
  const AnimalFormPage({this.animal, super.key});

  final Animal? animal;

  @override
  State<AnimalFormPage> createState() => _AnimalFormPageState();
}

class _AnimalFormPageState extends State<AnimalFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnimalService();

  late final _nom = TextEditingController(text: widget.animal?.nom);
  late final _race = TextEditingController(text: widget.animal?.race);
  late final _poids = TextEditingController(text: widget.animal?.poids?.toString());
  late final _couleur = TextEditingController(text: widget.animal?.couleur);
  late final _numero = TextEditingController(text: widget.animal?.numeroIdentification);
  late final _notes = TextEditingController(text: widget.animal?.notes);

  late String? _espece = widget.animal?.espece;
  late String? _sexe = widget.animal?.sexe;
  late int? _moisNaissance = widget.animal?.dateNaissance?.month;
  late int? _anneeNaissance = widget.animal?.dateNaissance?.year;

  bool _envoi = false;
  bool _especeManquante = false;
  ApiException? _erreurApi;

  bool get _modification => widget.animal != null;

  @override
  void dispose() {
    for (final c in [_nom, _race, _poids, _couleur, _numero, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _texte(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  /// Date envoyée à l'API : le 1er du mois choisi (ou janvier si seul l'an est choisi).
  DateTime? get _dateNaissance =>
      _anneeNaissance == null ? null : DateTime(_anneeNaissance!, _moisNaissance ?? 1, 1);

  Future<void> _enregistrer() async {
    setState(() {
      _erreurApi = null;
      _especeManquante = _espece == null;
    });
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _especeManquante) return;

    final animal = Animal(
      nom: _nom.text.trim(),
      espece: _espece!,
      sexe: _sexe!,
      race: _texte(_race),
      dateNaissance: _dateNaissance,
      poids: _texte(_poids) != null ? double.parse(_poids.text.trim().replaceAll(',', '.')) : null,
      couleur: _texte(_couleur),
      numeroIdentification: _texte(_numero),
      notes: _texte(_notes),
    );

    setState(() => _envoi = true);
    try {
      final enregistre = _modification
          ? await _service.modifier(widget.animal!.id!, animal)
          : await _service.creer(animal); // hors ligne : gardé sur l'appareil
      if (mounted) Navigator.of(context).pop(enregistre);
    } on ApiException catch (e) {
      setState(() => _erreurApi = e.horsLigne
          ? ApiException(0, 'Connexion nécessaire pour modifier un animal.')
          : e);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  InputDecoration _deco(String label, {String? champApi, String? suffix}) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      errorText: champApi != null ? _erreurApi?.erreurChamp(champApi) : null,
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const espace = SizedBox(height: 14);
    final anneeCourante = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(title: Text(_modification ? 'Modifier ${widget.animal!.nom}' : 'Ajouter un animal')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_erreurApi != null && _erreurApi!.errors.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(_erreurApi!.message, style: const TextStyle(color: Color(0xFFC62828))),
                  ),
                const Text('Espèce *', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                const SizedBox(height: 8),
                _grilleEspeces(),
                if (_especeManquante || _erreurApi?.erreurChamp('espece') != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _erreurApi?.erreurChamp('espece') ?? 'Choisissez une espèce',
                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nom,
                  decoration: _deco('Nom de l’animal *', champApi: 'nom'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                ),
                espace,
                TextFormField(controller: _race, decoration: _deco('Race (optionnel)', champApi: 'race')),
                espace,
                DropdownButtonFormField<String>(
                  value: _sexe,
                  decoration: _deco('Sexe *', champApi: 'sexe'),
                  items: [
                    for (final s in Animal.sexes.entries) DropdownMenuItem(value: s.key, child: Text(s.value)),
                  ],
                  onChanged: (v) => setState(() => _sexe = v),
                  validator: (v) => v == null ? 'Choisissez le sexe' : null,
                ),
                espace,
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _moisNaissance,
                        decoration: _deco('Mois de naissance'),
                        items: [
                          for (var m = 1; m <= 12; m++)
                            DropdownMenuItem(value: m, child: Text(Animal.mois[m - 1])),
                        ],
                        onChanged: (v) => setState(() => _moisNaissance = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _anneeNaissance,
                        decoration: _deco('Année', champApi: 'date_naissance'),
                        items: [
                          for (var y = anneeCourante; y >= anneeCourante - 30; y--)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) => setState(() => _anneeNaissance = v),
                        validator: (_) {
                          if (_moisNaissance != null && _anneeNaissance == null) return 'Choisissez l’année';
                          final d = _dateNaissance;
                          if (d != null && d.isAfter(DateTime.now())) return 'Date dans le futur';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Informations complémentaires (optionnel)'),
                  initiallyExpanded: _modification &&
                      (widget.animal!.poids != null ||
                          widget.animal!.numeroIdentification != null ||
                          widget.animal!.notes != null),
                  children: [
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _poids,
                      decoration: _deco('Poids', champApi: 'poids', suffix: 'kg'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim().replaceAll(',', '.'));
                        return (n == null || n < 0) ? 'Poids invalide' : null;
                      },
                    ),
                    espace,
                    TextFormField(controller: _couleur, decoration: _deco('Couleur / robe', champApi: 'couleur')),
                    espace,
                    TextFormField(
                      controller: _numero,
                      decoration: _deco('N° d’identification (boucle, puce…)', champApi: 'numero_identification'),
                    ),
                    espace,
                    TextFormField(controller: _notes, decoration: _deco('Notes', champApi: 'notes'), maxLines: 3),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _envoi ? null : _enregistrer,
                  child: _envoi
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Text('Enregistrer →'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Grille de 8 icônes cliquables (4 colonnes).
  Widget _grilleEspeces() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final e in Animal.especes.entries)
          _CaseEspece(
            emoji: e.value.$1,
            label: e.value.$2,
            selectionnee: _espece == e.key,
            onTap: () => setState(() {
              _espece = e.key;
              _especeManquante = false;
            }),
          ),
      ],
    );
  }
}

class _CaseEspece extends StatelessWidget {
  const _CaseEspece({
    required this.emoji,
    required this.label,
    required this.selectionnee,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selectionnee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionnee ? AppColors.lightGreen : AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selectionnee ? AppColors.green : AppColors.border,
              width: selectionnee ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selectionnee ? FontWeight.w800 : FontWeight.w500,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
