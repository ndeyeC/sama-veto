import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGreen,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 76),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final story = const _PreventionStory();
                final visual = const _PreventionVisual();
                return compact
                    ? Column(
                        children: [visual, const SizedBox(height: 36), story],
                      )
                    : Row(
                        children: [
                          Expanded(child: visual),
                          const SizedBox(width: 72),
                          Expanded(child: story),
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

class _PreventionStory extends StatelessWidget {
  const _PreventionStory();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MIEUX VAUT PRÉVENIR',
          style: TextStyle(
            color: AppColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'La prévention, un geste essentiel pour vos animaux',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 34,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'Un suivi régulier aide à repérer les changements, à garder une trace des '
          'soins et à agir plus tôt. Sama Veto rassemble les informations utiles '
          'pour vous aider à adopter les bons réflexes au quotidien.',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 15,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 24),
        const _PreventionPoint(
          icon: Icons.event_note_rounded,
          text: 'Gardez l’historique sanitaire de vos animaux.',
        ),
        const SizedBox(height: 14),
        const _PreventionPoint(
          icon: Icons.notifications_active_outlined,
          text: 'Pensez aux vaccinations et aux rappels.',
        ),
        const SizedBox(height: 14),
        const _PreventionPoint(
          icon: Icons.health_and_safety_outlined,
          text: 'Restez attentif aux signes inhabituels.',
        ),
      ],
    );
  }
}

class _PreventionPoint extends StatelessWidget {
  const _PreventionPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.green, size: 21),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PreventionVisual extends StatelessWidget {
  const _PreventionVisual();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEE1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 30,
              left: 30,
              child: Icon(
                Icons.add,
                color: AppColors.green.withValues(alpha: 0.35),
                size: 32,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 18,
              child: Icon(
                Icons.add,
                color: AppColors.green.withValues(alpha: 0.3),
                size: 42,
              ),
            ),
            Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: AppColors.green,
                size: 98,
              ),
            ),
            Positioned(
              left: 20,
              bottom: 25,
              child: _InfoPill(
                icon: Icons.favorite_rounded,
                label: 'Des animaux en bonne santé',
              ),
            ),
            Positioned(
              right: 18,
              top: 28,
              child: _InfoPill(
                icon: Icons.check_circle_rounded,
                label: 'Suivi régulier',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.green, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
