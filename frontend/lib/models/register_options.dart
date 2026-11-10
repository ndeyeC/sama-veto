/// Un profil proposé à l'inscription (reçu de l'API, jamais écrit en dur).
class RoleOption {
  const RoleOption({
    required this.key,
    required this.label,
    required this.emoji,
    required this.description,
  });

  final String key;
  final String label;
  final String emoji;
  final String description;

  factory RoleOption.fromJson(Map<String, dynamic> json) => RoleOption(
    key: json['key'] as String,
    label: json['label'] as String,
    emoji: json['emoji'] as String,
    description: json['description'] as String,
  );
}

/// Listes du formulaire d'inscription : régions et profils.
class RegisterOptions {
  const RegisterOptions({required this.regions, required this.roles});

  final List<String> regions;
  final List<RoleOption> roles;

  factory RegisterOptions.fromJson(Map<String, dynamic> json) =>
      RegisterOptions(
        regions: List<String>.from(json['regions'] as List),
        roles: (json['roles'] as List)
            .map((r) => RoleOption.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}
