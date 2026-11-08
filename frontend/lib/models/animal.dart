/// Un acte du carnet de santé (table `health_events`).
class HealthEvent {
  HealthEvent({
    this.id,
    required this.acte,
    required this.type,
    required this.datePrevue,
    this.dateRealisee,
    required this.statut,
  });

  final int? id;
  final String acte;
  final String type;
  final DateTime datePrevue;
  final DateTime? dateRealisee;

  /// fait | en_retard | bientot | prevu (calculé par le serveur)
  final String statut;

  bool get fait => statut == 'fait';

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      id: json['id'] as int?,
      acte: json['acte'] as String,
      type: json['type'] as String,
      datePrevue: DateTime.parse(json['date_prevue'] as String),
      dateRealisee: json['date_realisee'] != null
          ? DateTime.tryParse(json['date_realisee'] as String)
          : null,
      statut: json['statut'] as String? ?? 'prevu',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'acte': acte,
        'type': type,
        'date_prevue': Animal.formatDateApi(datePrevue),
        'date_realisee': dateRealisee != null ? Animal.formatDateApi(dateRealisee!) : null,
        'statut': statut,
      };
}

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
    this.statutSante = 'a_jour',
    this.couverture = 100,
    this.evenements = const [],
    this.idLocal,
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

  /// urgent | bientot | a_jour (calculé par le serveur)
  final String statutSante;

  /// % de couverture vaccinale (0-100), pour la barre de progression.
  final int couverture;

  /// Historique de santé, du plus récent au plus ancien.
  final List<HealthEvent> evenements;

  /// Renseigné quand l'animal a été ajouté hors ligne et attend la synchronisation.
  final String? idLocal;

  bool get enAttente => idLocal != null && id == null;

  /// Les 8 espèces du cahier des charges : clé API -> (emoji, libellé).
  static const especes = <String, (String, String)>{
    'bovin': ('🐄', 'Bovin'),
    'ovin': ('🐑', 'Ovin'),
    'caprin': ('🐐', 'Caprin'),
    'canin': ('🐕', 'Canin'),
    'volaille': ('🐓', 'Volaille'),
    'equin': ('🐎', 'Équin'),
    'felin': ('🐈', 'Félin'),
    'porcin': ('🐷', 'Porcin'),
  };

  static const sexes = <String, String>{'male': 'Mâle', 'femelle': 'Femelle'};

  static const mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  String get emoji => especes[espece]?.$1 ?? '🐾';
  String get especeLabel => especes[espece]?.$2 ?? espece;
  String get sexeLabel => sexes[sexe] ?? sexe;

  /// « mars 2023 » (on ne saisit que le mois et l'année).
  String? get naissanceLabel {
    final d = dateNaissance;
    return d == null ? null : '${mois[d.month - 1]} ${d.year}';
  }

  /// Âge lisible, ex. « 2 ans », « 5 mois ».
  String? get age {
    final naissance = dateNaissance;
    if (naissance == null) return null;
    final now = DateTime.now();
    final m = (now.year - naissance.year) * 12 + now.month - naissance.month;
    if (m < 1) return 'moins d’un mois';
    if (m < 12) return '$m mois';
    final ans = m ~/ 12;
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
      statutSante: json['statut_sante'] as String? ?? 'a_jour',
      couverture: (json['couverture'] as num?)?.toInt() ?? 100,
      evenements: (json['health_events'] as List? ?? [])
          .map((e) => HealthEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      idLocal: json['id_local'] as String?,
    );
  }

  /// Données envoyées à l'API (création / modification).
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

  /// Version complète pour le cache local (mode hors ligne).
  Map<String, dynamic> toCache() => {
        ...toJson(),
        'id': id,
        'statut_sante': statutSante,
        'couverture': couverture,
        'health_events': evenements.map((e) => e.toJson()).toList(),
        'id_local': idLocal,
      };

  /// Format attendu par l'API : AAAA-MM-JJ.
  static String formatDateApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_deuxChiffres(d.month)}-${_deuxChiffres(d.day)}';

  /// Format affiché : JJ/MM/AAAA.
  static String formatDateFr(DateTime d) => '${_deuxChiffres(d.day)}/${_deuxChiffres(d.month)}/${d.year}';

  static String _deuxChiffres(int n) => n.toString().padLeft(2, '0');
}
