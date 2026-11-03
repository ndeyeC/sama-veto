import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class HomeFooter extends StatelessWidget {
  const HomeFooter({
    required this.onHomeTap,
    required this.onFeaturesTap,
    required this.onAboutTap,
    required this.onVeterinariansTap,
    required this.onLoginTap,
    required this.onRegisterTap,
    super.key,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onFeaturesTap;
  final VoidCallback onAboutTap;
  final VoidCallback onVeterinariansTap;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 54, 24, 22),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;
                    final brand = const _FooterBrand();
                    final navigation = _FooterLinks(
                      onHomeTap: onHomeTap,
                      onFeaturesTap: onFeaturesTap,
                      onAboutTap: onAboutTap,
                      onVeterinariansTap: onVeterinariansTap,
                    );
                    final contact = _FooterContact(
                      onLoginTap: onLoginTap,
                      onRegisterTap: onRegisterTap,
                    );
                    return compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              brand,
                              const SizedBox(height: 30),
                              navigation,
                              const SizedBox(height: 26),
                              contact,
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: brand),
                              Expanded(flex: 3, child: navigation),
                              Expanded(flex: 3, child: contact),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 38),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '© 2026 Sama Veto. Tous droits réservés.',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.green,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Sama Veto',
              style: TextStyle(
                color: AppColors.darkGreen,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'La santé animale à portée de main. Un accompagnement simple pour '
          'mieux prendre soin de vos animaux, partout au Sénégal.',
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: 13,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks({
    required this.onHomeTap,
    required this.onFeaturesTap,
    required this.onAboutTap,
    required this.onVeterinariansTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onFeaturesTap;
  final VoidCallback onAboutTap;
  final VoidCallback onVeterinariansTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FooterTitle('Navigation'),
        const SizedBox(height: 12),
        _FooterLink(label: 'Accueil', onTap: onHomeTap),
        _FooterLink(label: 'Fonctionnalités', onTap: onFeaturesTap),
        _FooterLink(label: 'À propos', onTap: onAboutTap),
        _FooterLink(label: 'Vétérinaires', onTap: onVeterinariansTap),
      ],
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact({required this.onLoginTap, required this.onRegisterTap});

  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FooterTitle('Votre espace'),
        const SizedBox(height: 12),
        _FooterLink(label: 'Connexion', onTap: onLoginTap),
        _FooterLink(label: 'Créer un compte', onTap: onRegisterTap),
        const SizedBox(height: 13),
        const Row(
          children: [
            Icon(Icons.mail_outline_rounded, size: 17, color: AppColors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contactez-nous prochainement',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FooterTitle extends StatelessWidget {
  const _FooterTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.darkGreen,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
        ),
      ),
    );
  }
}
