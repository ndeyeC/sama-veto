import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'screens/animals/animals_page.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const SamaVetoApp());
}

class SamaVetoApp extends StatelessWidget {
  const SamaVetoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sama Veto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          primary: AppColors.green,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkGreen,
          elevation: 0,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.darkGreen,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      home: const HomePage(),
      routes: {
        '/animals': (context) => const AnimalsPage(),
        '/login': (context) => const AuthPlaceholderPage(
          title: 'Connexion',
          description:
              'L’espace de connexion Sama Veto sera bientôt disponible.',
        ),
        '/register': (context) => const AuthPlaceholderPage(
          title: 'Créer un compte',
          description:
              'La création de compte Sama Veto sera bientôt disponible.',
        ),
      },
    );
  }
}
