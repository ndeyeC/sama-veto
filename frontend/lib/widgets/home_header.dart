import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
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
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _menuOpen = false;

  void _select(VoidCallback callback) {
    setState(() => _menuOpen = false);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: 14,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _Brand(),
                        const Spacer(),
                        if (!isMobile) ...[
                          _NavButton(
                            label: 'Accueil',
                            onPressed: widget.onHomeTap,
                          ),
                          _NavButton(
                            label: 'Fonctionnalités',
                            onPressed: widget.onFeaturesTap,
                          ),
                          _NavButton(
                            label: 'À propos',
                            onPressed: widget.onAboutTap,
                          ),
                          _NavButton(
                            label: 'Vétérinaires',
                            onPressed: widget.onVeterinariansTap,
                          ),
                          const SizedBox(width: 14),
                          TextButton(
                            onPressed: widget.onLoginTap,
                            child: const Text('Connexion'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: widget.onRegisterTap,
                            child: const Text('Créer un compte'),
                          ),
                        ] else
                          IconButton(
                            tooltip: _menuOpen
                                ? 'Fermer le menu'
                                : 'Ouvrir le menu',
                            onPressed: () =>
                                setState(() => _menuOpen = !_menuOpen),
                            icon: Icon(_menuOpen ? Icons.close : Icons.menu),
                            color: AppColors.darkGreen,
                          ),
                      ],
                    ),
                    if (isMobile && _menuOpen)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MobileNavButton(
                              label: 'Accueil',
                              onPressed: () => _select(widget.onHomeTap),
                            ),
                            _MobileNavButton(
                              label: 'Fonctionnalités',
                              onPressed: () => _select(widget.onFeaturesTap),
                            ),
                            _MobileNavButton(
                              label: 'À propos',
                              onPressed: () => _select(widget.onAboutTap),
                            ),
                            _MobileNavButton(
                              label: 'Vétérinaires',
                              onPressed: () =>
                                  _select(widget.onVeterinariansTap),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => _select(widget.onLoginTap),
                              child: const Text('Connexion'),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: () => _select(widget.onRegisterTap),
                              child: const Text('Créer un compte'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: AppColors.green,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sama Veto',
          style: TextStyle(
            color: AppColors.darkGreen,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.text),
      child: Text(label),
    );
  }
}

class _MobileNavButton extends StatelessWidget {
  const _MobileNavButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: AppColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
