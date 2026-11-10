import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/register_options.dart';
import 'storage_service.dart';

/// Erreur renvoyée par l'API (ou réseau), avec un message déjà lisible
/// par l'utilisateur et, pour les erreurs de validation (422), les
/// messages par champ : { 'email': 'Cette adresse email est déjà utilisée.' }.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class ApiService {
  final StorageService _storageService = StorageService();

  static const Duration _timeout = Duration(seconds: 15);

  // ---------------------------------------------------------------------------
  // Authentification et profil
  // ---------------------------------------------------------------------------

  /// Régions et profils proposés à l'inscription (fournis par l'API).
  Future<RegisterOptions> getRegisterOptions() async {
    final data = await get(ApiConstants.registerOptions);
    return RegisterOptions.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Inscription : enregistre le token (l'utilisateur est connecté tout de
  /// suite) et retourne l'utilisateur créé.
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String region,
    required String role,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await post(ApiConstants.register, {
      'name': name,
      'phone': phone,
      'region': region,
      'role': role,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    return _saveSession(data);
  }

  /// Connexion par téléphone : enregistre le token et retourne l'utilisateur.
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final data = await post(ApiConstants.login, {
      'phone': phone,
      'password': password,
    });

    return _saveSession(data);
  }

  /// Déconnexion : révoque le token côté serveur puis le supprime localement.
  /// Le token local est supprimé même si le serveur est injoignable.
  Future<void> logout() async {
    try {
      await post(ApiConstants.logout, {}, authenticated: true);
    } on ApiException catch (e) {
      // 401 = token déjà invalide côté serveur : rien d'autre à faire.
      if (e.statusCode != 401) rethrow;
    } finally {
      await _storageService.deleteToken();
    }
  }

  /// Profil de l'utilisateur connecté.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final data = await get(ApiConstants.profile, authenticated: true);
      return Map<String, dynamic>.from(data['user'] as Map);
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _storageService.deleteToken();
      rethrow;
    }
  }

  /// Mise à jour du profil (nom, téléphone, région). Le rôle est définitif.
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String phone,
    required String region,
  }) async {
    final data = await put(ApiConstants.profile, {
      'name': name,
      'phone': phone,
      'region': region,
    }, authenticated: true);

    return Map<String, dynamic>.from(data['user'] as Map);
  }

  /// Changement de mot de passe.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    await put(ApiConstants.changePassword, {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPasswordConfirmation,
    }, authenticated: true);
  }

  Future<bool> isLoggedIn() => _storageService.hasToken();

  Future<Map<String, dynamic>> _saveSession(dynamic data) async {
    await _storageService.saveToken(data['token'] as String);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  // ---------------------------------------------------------------------------
  // Requêtes HTTP génériques (utilisables par les autres fonctionnalités)
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _storageService.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool authenticated = false}) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ),
    );
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool authenticated = false,
  }) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
  }

  Future<dynamic> delete(String endpoint, {bool authenticated = false}) async {
    final headers = await _headers(authenticated: authenticated);
    return _send(
      () => http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: headers,
      ),
    );
  }

  /// Exécute la requête et transforme les problèmes réseau en [ApiException].
  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Le serveur met trop de temps à répondre. Veuillez réessayer.',
      );
    } catch (_) {
      throw ApiException(
        'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        body = null;
      }
    }

    final status = response.statusCode;
    if (status >= 200 && status < 300) {
      return body;
    }

    final fieldErrors = <String, String>{};
    String? serverMessage;

    if (body is Map) {
      if (body['message'] is String) {
        serverMessage = body['message'] as String;
      }
      final errors = body['errors'];
      if (errors is Map) {
        errors.forEach((field, messages) {
          if (messages is List && messages.isNotEmpty) {
            fieldErrors[field.toString()] = messages.first.toString();
          }
        });
      }
    }

    late final String message;
    if (status == 422 && fieldErrors.isNotEmpty) {
      message = fieldErrors.values.first;
    } else if (status == 429) {
      message = 'Trop de tentatives. Veuillez réessayer dans quelques instants.';
    } else if (status >= 500) {
      message = 'Erreur du serveur. Veuillez réessayer plus tard.';
    } else if (status == 401 && serverMessage != null) {
      message = serverMessage;
    } else if (status == 401) {
      message = 'Session expirée. Veuillez vous reconnecter.';
    } else {
      message = serverMessage ?? 'Une erreur est survenue (code $status).';
    }

    throw ApiException(message, statusCode: status, fieldErrors: fieldErrors);
  }
}
