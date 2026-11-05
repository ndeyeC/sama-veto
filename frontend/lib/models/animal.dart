/// Modèle Animal : correspond à la table `animals` du backend Laravel.
class Animal {
  Animal({
    this.id,
    required this.nom,
    required this.espece,
    required this.sexe,
    this.race,
    this.dateNaissance,
    this.poids,
    this.couleur,
    this.numeroIdentification,
    this.notes,
  });

  final int? id;
  final String nom;
  final String espece;
  final String sexe;
  final String? race;
  final DateTime? dateNaissance;
  final double? poids;
  final String? couleur;
  final String? numeroIdentification;
  final String? notes;

  /// Espèces acceptées par l'API (clé) et leur libellé affiché (valeur).
  static const especes = <String, String>{
    'bovin': 'Bovin',
    'ovin': 'Ovin',
    'caprin': 'Caprin',
    'volaille': 'Volaille',
    'equin': 'Équin',
    'chien': 'Chien',
    'chat': 'Chat',
    'autre': 'Autre',
  };

  static const sexes = <String, String>{'male': 'Mâle', 'femelle': 'Femelle'};

  String get especeLabel => especes[espece] ?? espece;
  String get sexeLabel => sexes[sexe] ?? sexe;

  /// Âge lisible, ex. « 2 ans », « 5 mois ».
  String? get age {
    final naissance = dateNaissance;
    if (naissance == null) return null;
    final now = DateTime.now();
    var mois = (now.year - naissance.year) * 12 + now.month - naissance.month;
    if (now.day < naissance.day) mois--;
    if (mois < 1) return 'moins d’un mois';
    if (mois < 12) return '$mois mois';
    final ans = mois ~/ 12;
    return ans == 1 ? '1 an' : '$ans ans';
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      espece: json['espece'] as String,
      sexe: json['sexe'] as String,
      race: json['race'] as String?,
      dateNaissance: json['date_naissance'] != null
          ? DateTime.tryParse(json['date_naissance'] as String)
          : null,
      poids: json['poids'] != null ? (json['poids'] as num).toDouble() : null,
      couleur: json['couleur'] as String?,
      numeroIdentification: json['numero_identification'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'espece': espece,
      'sexe': sexe,
      'race': race,
      'date_naissance': dateNaissance != null ? formatDateApi(dateNaissance!) : null,
      'poids': poids,
      'couleur': couleur,
      'numero_identification': numeroIdentification,
      'notes': notes,
    };
  }

  /// Format attendu par l'API : AAAA-MM-JJ.
  static String formatDateApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_2(d.month)}-${_2(d.day)}';

  /// Format affiché : JJ/MM/AAAA.
  static String formatDateFr(DateTime d) => '${_2(d.day)}/${_2(d.month)}/${d.year}';

  static String _2(int n) => n.toString().padLeft(2, '0');
}
