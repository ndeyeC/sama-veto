import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    required this.onStartTap,
    required this.onServicesTap,
    super.key,
  });

  final VoidCallback onStartTap;
  final VoidCallback onServicesTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 58),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final copy = _HeroCopy(
                  onStartTap: onStartTap,
                  onServicesTap: onServicesTap,
                  compact: compact,
                );
                return compact
                    ? Column(
                        children: [
                          copy,
                          const SizedBox(height: 48),
                          const _HeroIllustration(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 11, child: copy),
                          const SizedBox(width: 36),
                          const Expanded(flex: 9, child: _HeroIllustration()),
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

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.onStartTap,
    required this.onServicesTap,
    required this.compact,
  });

  final VoidCallback onStartTap;
  final VoidCallback onServicesTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'LE BIEN-ÊTRE ANIMAL, ENSEMBLE',
            style: TextStyle(
              color: AppColors.green,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: compact ? 40 : 54,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.8,
              color: AppColors.darkGreen,
            ),
            children: const [
              TextSpan(text: 'La santé animale\nà '),
              TextSpan(
                text: 'portée de main.',
                style: TextStyle(color: AppColors.green),
              ),
            ],
          ),
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Sama Veto vous accompagne pour prendre soin de vos animaux : '
            'suivi sanitaire, prévention et mise en relation avec des '
            'professionnels près de chez vous.',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 16,
              height: 1.75,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onStartTap,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Commencer maintenant'),
            ),
            OutlinedButton(
              onPressed: onServicesTap,
              child: const Text('Découvrir nos services'),
            ),
          ],
        ),
        const SizedBox(height: 30),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          runSpacing: 10,
          children: [
            _TrustItem(
              icon: Icons.check_circle_outline,
              text: 'Simple à utiliser',
            ),
            _TrustItem(
              icon: Icons.favorite_border,
              text: 'Pensé pour vos animaux',
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: AppColors.green),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EE),
              borderRadius: BorderRadius.circular(36),
            ),
          ),
          Positioned(
            top: 28,
            right: 34,
            child: _decorativeCircle(72, const Color(0xFFD8EBDD)),
          ),
          Positioned(
            left: 28,
            bottom: 40,
            child: _decorativeCircle(48, const Color(0xFFD8EBDD)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFD6E9D9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(36),
                ),
              ),
            ),
          ),
          Positioned(
            right: 34,
            bottom: 46,
            child: Icon(
              Icons.grass_rounded,
              color: AppColors.green.withValues(alpha: 0.45),
              size: 72,
            ),
          ),
          Positioned(
            left: 34,
            top: 54,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.darkGreen.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.health_and_safety, color: AppColors.green),
                  SizedBox(width: 8),
                  Text(
                    'La prévention avant tout',
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
          Positioned(
            bottom: 55,
            left: 0,
            right: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _AnimalIllustration(
                    icon: Icons.agriculture_rounded,
                    color: Color(0xFFB77C4A),
                    size: 112,
                    rotate: -0.04,
                  ),
                  SizedBox(width: 10),
                  _AnimalIllustration(
                    icon: Icons.pets_rounded,
                    color: AppColors.green,
                    size: 150,
                    rotate: 0,
                  ),
                  SizedBox(width: 10),
                  _AnimalIllustration(
                    icon: Icons.park_rounded,
                    color: Color(0xFFD28D4A),
                    size: 105,
                    rotate: 0.04,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 38,
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_rounded,
                color: AppColors.green,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _decorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AnimalIllustration extends StatelessWidget {
  const _AnimalIllustration({
    required this.icon,
    required this.color,
    required this.size,
    required this.rotate,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double rotate;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotate,
      child: Container(
        width: size * 0.72,
        height: size * 0.82,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(size * 0.36),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGreen.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.56),
      ),
    );
  }
}
