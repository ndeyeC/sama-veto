import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';

/// Formulaire d'ajout (animal == null) ou de modification d'un animal.
/// Renvoie `true` à l'écran précédent si l'enregistrement a réussi.
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
  late DateTime? _dateNaissance = widget.animal?.dateNaissance;

  bool _envoi = false;
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

  Future<void> _choisirDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dateNaissance ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Date de naissance',
    );
    if (d != null) setState(() => _dateNaissance = d);
  }

  Future<void> _enregistrer() async {
    setState(() => _erreurApi = null);
    if (!_formKey.currentState!.validate()) return;

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
      if (_modification) {
        await _service.modifier(widget.animal!.id!, animal);
      } else {
        await _service.creer(animal);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_modification ? 'Animal modifié.' : 'Animal enregistré.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erreurApi = e);
      _formKey.currentState!.validate(); // affiche les erreurs renvoyées par Laravel
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
    return Scaffold(
      appBar: AppBar(title: Text(_modification ? 'Modifier ${widget.animal!.nom}' : 'Nouvel animal')),
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
                    child: Text(_erreurApi!.message, style: TextStyle(color: Colors.red.shade700)),
                  ),
                TextFormField(
                  controller: _nom,
                  decoration: _deco('Nom *', champApi: 'nom'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire' : null,
                ),
                espace,
                DropdownButtonFormField<String>(
                  value: _espece,
                  decoration: _deco('Espèce *', champApi: 'espece'),
                  items: [
                    for (final e in Animal.especes.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => _espece = v),
                  validator: (v) => v == null ? 'Choisissez une espèce' : null,
                ),
                espace,
                TextFormField(controller: _race, decoration: _deco('Race', champApi: 'race')),
                espace,
                FormField<String>(
                  initialValue: _sexe,
                  validator: (_) => _sexe == null ? 'Choisissez le sexe' : null,
                  builder: (state) => InputDecorator(
                    decoration: _deco('Sexe *', champApi: 'sexe').copyWith(errorText: state.errorText),
                    child: SegmentedButton<String>(
                      emptySelectionAllowed: true,
                      segments: [
                        for (final s in Animal.sexes.entries)
                          ButtonSegment(value: s.key, label: Text(s.value)),
                      ],
                      selected: {if (_sexe != null) _sexe!},
                      onSelectionChanged: (sel) {
                        setState(() => _sexe = sel.isEmpty ? null : sel.first);
                        state.didChange(_sexe);
                      },
                    ),
                  ),
                ),
                espace,
                InkWell(
                  onTap: _choisirDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _deco('Date de naissance', champApi: 'date_naissance').copyWith(
                      suffixIcon: _dateNaissance != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _dateNaissance = null),
                            )
                          : const Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      _dateNaissance != null ? Animal.formatDateFr(_dateNaissance!) : 'Non renseignée',
                    ),
                  ),
                ),
                espace,
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
                TextFormField(
                  controller: _notes,
                  decoration: _deco('Notes', champApi: 'notes'),
                  maxLines: 3,
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
                      : Text(_modification ? 'Enregistrer les modifications' : 'Ajouter l’animal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
