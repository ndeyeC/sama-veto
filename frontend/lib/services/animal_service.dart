import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  /// statusCode 0 = le serveur n'a pas pu être joint (pas d'internet).
  bool get horsLigne => statusCode == 0;

  /// Première erreur d'un champ (pour l'afficher sous le champ du formulaire).
  String? erreurChamp(String champ) => errors[champ]?.first;

  @override
  String toString() => message;
}

/// Résultat du chargement de la liste.
class ListeAnimaux {
  ListeAnimaux(this.animaux, {this.horsLigne = false});

  final List<Animal> animaux;

  /// true si les données viennent du cache local (pas de connexion).
  final bool horsLigne;

  int get total => animaux.length;
  int get aPlanifier => animaux.where((a) => a.statutSante == 'bientot').length;
  int get urgences => animaux.where((a) => a.statutSante == 'urgent').length;
  int get enAttente => animaux.where((a) => a.enAttente).length;
}

/// Appels API de l'onglet Animaux, avec cache local pour le mode hors ligne
/// (règles 1 et 4 du cahier des charges, tests 4 et 7).
class AnimalService {
  final StorageService _storage = StorageService();

  static const _cleCache = 'animaux_cache';
  static const _cleEnAttente = 'animaux_en_attente';

  /// Charge tous les animaux. Envoie d'abord les ajouts faits hors ligne.
  /// Sans connexion : renvoie la dernière liste en cache + les ajouts en attente.
  Future<ListeAnimaux> lister() async {
    try {
      await synchroniser();
      final body = await _request('GET', ApiConstants.animals);
      final animaux = (body['data'] as List)
          .map((e) => Animal.fromJson(e as Map<String, dynamic>))
          .toList();
      await _sauverCache(animaux);
      return ListeAnimaux([...await _lireEnAttente(), ...animaux]);
    } on ApiException catch (e) {
      if (!e.horsLigne) rethrow;
      return ListeAnimaux([...await _lireEnAttente(), ...await _lireCache()], horsLigne: true);
    }
  }

  /// Crée l'animal. Sans connexion, il est gardé sur l'appareil et envoyé plus tard.
  /// Renvoie l'animal créé (ou l'animal « en attente »).
  Future<Animal> creer(Animal animal) async {
    try {
      final body = await _request('POST', ApiConstants.animals, data: animal.toJson());
      return Animal.fromJson(body['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (!e.horsLigne) rethrow;
      final aujourdhui = DateTime.now();
      final local = Animal.fromJson({
        ...animal.toJson(),
        'id_local': 'local-${aujourdhui.microsecondsSinceEpoch}',
        'health_events': [
          HealthEvent(
            acte: 'Enregistrement initial',
            type: 'enregistrement',
            datePrevue: aujourdhui,
            dateRealisee: aujourdhui,
            statut: 'fait',
          ).toJson(),
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final liste = prefs.getStringList(_cleEnAttente) ?? [];
      liste.add(jsonEncode(local.toCache()));
      await prefs.setStringList(_cleEnAttente, liste);
      return local;
    }
  }

  /// Envoie au serveur les animaux ajoutés hors ligne. S'arrête sans erreur si toujours hors ligne.
  Future<int> synchroniser() async {
    final prefs = await SharedPreferences.getInstance();
    final liste = prefs.getStringList(_cleEnAttente) ?? [];
    if (liste.isEmpty) return 0;

    final restants = <String>[];
    var envoyes = 0;
    for (var i = 0; i < liste.length; i++) {
      final animal = Animal.fromJson(jsonDecode(liste[i]) as Map<String, dynamic>);
      try {
        await _request('POST', ApiConstants.animals, data: animal.toJson());
        envoyes++;
      } on ApiException catch (e) {
        if (e.horsLigne || e.nonConnecte) {
          restants.addAll(liste.sublist(i)); // on réessaiera plus tard
          await prefs.setStringList(_cleEnAttente, restants);
          if (e.nonConnecte) rethrow;
          return envoyes;
        }
        // Refusé par le serveur (ex. numéro déjà utilisé) : on l'abandonne pour ne pas bloquer la file.
      }
    }
    await prefs.setStringList(_cleEnAttente, restants);
    return envoyes;
  }

  Future<Animal> detail(int id) async {
    final body = await _request('GET', '${ApiConstants.animals}/$id');
    return Animal.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<Animal> modifier(int id, Animal animal) async {
    final body = await _request('PUT', '${ApiConstants.animals}/$id', data: animal.toJson());
    return Animal.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> supprimer(Animal animal) async {
    if (animal.enAttente) {
      // Pas encore envoyé au serveur : on le retire juste de la file d'attente.
      final prefs = await SharedPreferences.getInstance();
      final liste = (prefs.getStringList(_cleEnAttente) ?? [])
          .where((s) => (jsonDecode(s) as Map)['id_local'] != animal.idLocal)
          .toList();
      await prefs.setStringList(_cleEnAttente, liste);
      return;
    }
    await _request('DELETE', '${ApiConstants.animals}/${animal.id}');
  }

  /// Marque un acte du carnet comme réalisé aujourd'hui. Renvoie l'animal à jour.
  Future<Animal> marquerFait(int animalId, int eventId) async {
    final body = await _request(
      'PATCH',
      '${ApiConstants.animals}/$animalId/events/$eventId/fait',
    );
    return Animal.fromJson(body['animal'] as Map<String, dynamic>);
  }

  /// TEMPORAIRE : récupère un jeton du compte démo (route /dev/token, APP_ENV=local).
  /// À retirer quand l'écran de connexion de l'équipe auth sera fusionné.
  Future<void> connexionDemo() async {
    final body = await _request('POST', ApiConstants.devToken, authentifie: false);
    await _storage.saveToken(body['token'] as String);
  }

  // ---------------------------------------------------------------- cache

  Future<void> _sauverCache(List<Animal> animaux) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleCache, jsonEncode(animaux.map((a) => a.toCache()).toList()));
  }

  Future<List<Animal>> _lireCache() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString(_cleCache);
    if (brut == null) return [];
    return (jsonDecode(brut) as List)
        .map((e) => Animal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Animal>> _lireEnAttente() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_cleEnAttente) ?? [])
        .map((s) => Animal.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  // ---------------------------------------------------------------- HTTP

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    bool authentifie = true,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (authentifie) {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (data != null) req.body = jsonEncode(data);
      response = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 10)),
      );
    } catch (_) {
      throw ApiException(0, 'Pas de connexion au serveur.');
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
