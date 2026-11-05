import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    _Feature(
      icon: Icons.pets_rounded,
      color: Color(0xFF167C55),
      title: 'Gestion des animaux',
      description:
          'Enregistrez vos animaux et gardez leurs informations utiles à portée de main.',
      route: '/animals',
    ),
    _Feature(
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF4689C8),
      title: 'Suivi sanitaire',
      description:
          'Retrouvez facilement les soins et les événements de santé de vos animaux.',
    ),
    _Feature(
      icon: Icons.vaccines_rounded,
      color: Color(0xFFD28D4A),
      title: 'Vaccinations',
      description:
          'Notez les vaccinations et gardez un œil sur les prochains rappels.',
    ),
    _Feature(
      icon: Icons.medical_services_rounded,
      color: Color(0xFF8A6CB0),
      title: 'Vétérinaires',
      description:
          'Recherchez des professionnels vétérinaires proches de votre localité.',
    ),
    _Feature(
      icon: Icons.campaign_rounded,
      color: Color(0xFFD27643),
      title: 'Alertes sanitaires',
      description:
          'Restez attentif aux informations de prévention et aux risques signalés.',
    ),
    _Feature(
      icon: Icons.report_gmailerrorred_rounded,
      color: Color(0xFFBA5960),
      title: 'Signalements',
      description:
          'Partagez rapidement un cas suspect pour encourager la vigilance collective.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 78),
          child: Column(
            children: [
              const _SectionHeading(
                eyebrow: 'VOTRE QUOTIDIEN, SIMPLIFIÉ',
                title: 'Tout pour mieux prendre soin',
                description:
                    'Des outils pratiques pour accompagner les éleveurs et les propriétaires '
                    'dans le suivi de la santé animale.',
              ),
              const SizedBox(height: 38),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 3
                      : constraints.maxWidth >= 580
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - ((columns - 1) * 18)) / columns;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: [
                      for (final feature in _features)
                        SizedBox(
                          width: width,
                          child: _FeatureCard(feature: feature),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String? route;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    final route = feature.route;
    final card = _buildCard();
    if (route == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).pushNamed(route),
        child: card,
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(minHeight: 208),
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(feature.icon, color: feature.color, size: 25),
          ),
          const SizedBox(height: 19),
          Text(
            feature.title,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.darkGreen,
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }
}
