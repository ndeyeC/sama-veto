import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class VeterinarySection extends StatelessWidget {
  const VeterinarySection({required this.onFindVeterinarianTap, super.key});

  final VoidCallback onFindVeterinarianTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 78),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.circular(28),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final content = _VeterinaryMessage(
                  onFindVeterinarianTap: onFindVeterinarianTap,
                  compact: compact,
                );
                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          content,
                          const SizedBox(height: 32),
                          const _LocationIllustration(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 6, child: content),
                          const SizedBox(width: 30),
                          const Expanded(
                            flex: 5,
                            child: _LocationIllustration(),
                          ),
                        ],
                      );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VeterinaryMessage extends StatelessWidget {
  const _VeterinaryMessage({
    required this.onFindVeterinarianTap,
    required this.compact,
  });

  final VoidCallback onFindVeterinarianTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'À VOS CÔTÉS, PRÈS DE CHEZ VOUS',
          style: TextStyle(
            color: Color(0xFFB9E2C7),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Un vétérinaire, au plus près de vos besoins.',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Repérez les professionnels vétérinaires à proximité de votre localité '
          'et facilitez la prise de contact lorsque vos animaux ont besoin de soins.',
          style: TextStyle(
            color: Color(0xFFD7E8DE),
            fontSize: 14,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onFindVeterinarianTap,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.darkGreen,
          ),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Trouver un vétérinaire'),
        ),
        if (compact) const SizedBox(height: 8),
      ],
    );
  }
}

class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1B6349),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 34,
            top: 32,
            child: Icon(
              Icons.circle,
              color: AppColors.white.withValues(alpha: 0.08),
              size: 90,
            ),
          ),
          Positioned(
            right: 28,
            bottom: 12,
            child: Icon(
              Icons.circle,
              color: AppColors.white.withValues(alpha: 0.07),
              size: 120,
            ),
          ),
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFB9E2C7),
            size: 100,
          ),
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.near_me_rounded, size: 16, color: AppColors.green),
                  SizedBox(width: 7),
                  Text(
                    'La proximité, simplement',
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
