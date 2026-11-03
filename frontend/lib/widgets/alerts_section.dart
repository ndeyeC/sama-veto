import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AlertsSection extends StatelessWidget {
  const AlertsSection({required this.onReportTap, super.key});

  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EE),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFF3E8D6)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final message = _AlertMessage(onReportTap: onReportTap);
                final visual = const _AlertVisual();

                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [message, const SizedBox(height: 28), visual],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 6, child: message),
                          const SizedBox(width: 32),
                          Expanded(flex: 4, child: visual),
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

class _AlertMessage extends StatelessWidget {
  const _AlertMessage({required this.onReportTap});

  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VIGILANCE COLLECTIVE',
          style: TextStyle(
            color: Color(0xFF9A672E),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Face à un cas suspect, chaque signalement compte.',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Les informations sanitaires et les alertes épidémiologiques aident '
          'chacun à rester attentif. En cas de signe inhabituel, rapprochez-vous '
          'd’un professionnel et signalez la situation rapidement.',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 14,
            height: 1.75,
          ),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onReportTap,
          style: FilledButton.styleFrom(backgroundColor: AppColors.darkGreen),
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Créer un compte pour signaler'),
        ),
      ],
    );
  }
}

class _AlertVisual extends StatelessWidget {
  const _AlertVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFFF5EAD9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30,
            top: 28,
            child: Icon(
              Icons.circle,
              color: const Color(0xFFD8B98D).withValues(alpha: 0.3),
              size: 74,
            ),
          ),
          Positioned(
            right: 24,
            bottom: 14,
            child: Icon(
              Icons.circle,
              color: const Color(0xFFD8B98D).withValues(alpha: 0.25),
              size: 112,
            ),
          ),
          Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFB77C36),
              size: 58,
            ),
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
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: AppColors.green,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'La prévention est collective',
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
