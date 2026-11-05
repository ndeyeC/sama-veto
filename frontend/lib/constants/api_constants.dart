class ApiConstants {
  // Adresse du backend Laravel pour Flutter Web
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Routes API
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String profile = '/user';

  // Gestion des animaux
  static const String animals = '/animals';
  static const String animalsStats = '/animals/stats';
  static const String devToken = '/dev/token'; // TEMPORAIRE (dev)
}
