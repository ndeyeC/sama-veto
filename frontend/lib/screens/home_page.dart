import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/about_section.dart';
import '../widgets/alerts_section.dart';
import '../widgets/features_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/home_footer.dart';
import '../widgets/home_header.dart';
import '../widgets/veterinary_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _heroKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _veterinaryKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
      alignment: 0.04,
    );
  }

  void _openAuth(String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HomeHeader(
            onHomeTap: () => _scrollTo(_heroKey),
            onFeaturesTap: () => _scrollTo(_featuresKey),
            onAboutTap: () => _scrollTo(_aboutKey),
            onVeterinariansTap: () => _scrollTo(_veterinaryKey),
            onLoginTap: () => _openAuth('/login'),
            onRegisterTap: () => _openAuth('/register'),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    key: _heroKey,
                    child: HeroSection(
                      onStartTap: () => _openAuth('/register'),
                      onServicesTap: () => _scrollTo(_featuresKey),
                    ),
                  ),
                  Container(key: _featuresKey, child: const FeaturesSection()),
                  Container(key: _aboutKey, child: const AboutSection()),
                  AlertsSection(onReportTap: () => _openAuth('/register')),
                  Container(
                    key: _veterinaryKey,
                    child: VeterinarySection(
                      onFindVeterinarianTap: () => _openAuth('/register'),
                    ),
                  ),
                  HomeFooter(
                    onHomeTap: () => _scrollTo(_heroKey),
                    onFeaturesTap: () => _scrollTo(_featuresKey),
                    onAboutTap: () => _scrollTo(_aboutKey),
                    onVeterinariansTap: () => _scrollTo(_veterinaryKey),
                    onLoginTap: () => _openAuth('/login'),
                    onRegisterTap: () => _openAuth('/register'),
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

class AuthPlaceholderPage extends StatelessWidget {
  const AuthPlaceholderPage({
    required this.title,
    required this.description,
    super.key,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkGreen,
        title: const Text('Sama Veto'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppColors.lightGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.green,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Retour à l’accueil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
