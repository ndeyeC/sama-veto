import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/animal.dart';
import 'storage_service.dart';

/// Erreur renvoyée par l'API, avec les erreurs de validation Laravel (422).
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.errors = const {}});

  final int statusCode;
  final String message;
  final Map<String, List<String>> errors;

  bool get nonConnecte => statusCode == 401;

  /// Première erreur d'un champ (pour l'afficher sous le champ du formulaire).
  String? erreurChamp(String champ) => errors[champ]?.first;

  @override
  String toString() => message;
}

/// Appels API pour la gestion des animaux (CRUD + statistiques).
class AnimalService {
  final StorageService _storage = StorageService();

  Future<List<Animal>> lister({String? espece, String? recherche}) async {
    final params = <String, String>{
      if (espece != null && espece.isNotEmpty) 'espece': espece,
      if (recherche != null && recherche.trim().isNotEmpty) 'search': recherche.trim(),
    };
    final body = await _request('GET', ApiConstants.animals, query: params);
    return (body['data'] as List)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> statistiques() async {
    final body = await _request('GET', ApiConstants.animalsStats);
    return body['data'] as Map<String, dynamic>;
  }

  Future<Animal> creer(Animal animal) async {
    final body = await _request('POST', ApiConstants.animals, data: animal.toJson());
    return Animal.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Animal> modifier(int id, Animal animal) async {
    final body = await _request('PUT', '${ApiConstants.animals}/$id', data: animal.toJson());
    return Animal.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> supprimer(int id) async {
    await _request('DELETE', '${ApiConstants.animals}/$id');
  }

  /// TEMPORAIRE : récupère un jeton du compte démo (route /dev/token, APP_ENV=local).
  /// À retirer quand l'écran de connexion de l'équipe auth sera fusionné.
  Future<void> connexionDemo() async {
    final body = await _request('POST', ApiConstants.devToken, authentifie: false);
    await _storage.saveToken(body['token'] as String);
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? query,
    bool authentifie = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: (query == null || query.isEmpty) ? null : query);

    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (authentifie) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (data != null) req.body = jsonEncode(data);
      response = await http.Response.fromStream(await req.send());
    } catch (_) {
      throw ApiException(0, 'Impossible de joindre le serveur. Vérifiez que Laravel tourne (php artisan serve).');
    }

    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    final map = body is Map<String, dynamic> ? body : <String, dynamic>{};
    final errors = <String, List<String>>{};
    if (map['errors'] is Map) {
      (map['errors'] as Map).forEach((k, v) {
        errors[k as String] = (v as List).map((e) => e.toString()).toList();
      });
    }
    final message = switch (response.statusCode) {
      401 => 'Vous devez être connecté pour gérer vos animaux.',
      404 => 'Animal introuvable.',
      422 => 'Veuillez corriger les champs indiqués.',
      _ => (map['message'] as String?) ?? 'Erreur ${response.statusCode}',
    };
    throw ApiException(response.statusCode, message, errors: errors);
  }
}
