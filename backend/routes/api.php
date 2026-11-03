<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Route de test pour vérifier la communication avec Flutter
Route::get('/test', function () {
    return response()->json([
        'success' => true,
        'message' => 'Connexion entre Flutter et Laravel réussie !',
    ]);
});

// Route protégée : récupérer le profil de l'utilisateur connecté
Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');