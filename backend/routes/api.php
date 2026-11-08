<?php

use App\Http\Controllers\AnimalController;
use App\Models\User;
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

/*
|--------------------------------------------------------------------------
| Gestion des animaux (BA)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/animals/stats', [AnimalController::class, 'stats']);
    Route::apiResource('animals', AnimalController::class);
    Route::post('/animals/{animal}/events', [AnimalController::class, 'ajouterEvenement']);
    Route::patch('/animals/{animal}/events/{event}/fait', [AnimalController::class, 'marquerFait']);
});

/*
| TEMPORAIRE (dev uniquement) : donne un jeton pour tester la gestion des
| animaux tant que l'authentification n'est pas fusionnée.
| Ne fonctionne que si APP_ENV=local. À supprimer après la fusion de l'auth.
*/
if (app()->environment('local')) {
    Route::post('/dev/token', function () {
        $user = User::firstOrCreate(
            ['email' => 'demo@samaveto.sn'],
            ['name' => 'Éleveur Démo', 'password' => 'password']
        );

        return response()->json([
            'token' => $user->createToken('dev')->plainTextToken,
            'user' => $user,
        ]);
    });
}
