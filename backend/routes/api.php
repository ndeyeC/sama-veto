<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// Route de test pour vérifier la communication avec Flutter
Route::get('/test', function () {
    return response()->json([
        'success' => true,
        'message' => 'Connexion entre Flutter et Laravel réussie !',
    ]);
});

/*
|--------------------------------------------------------------------------
| Authentification & profil (branche feature/authentification)
|--------------------------------------------------------------------------
*/

// Routes publiques
Route::get('/auth/options', [AuthController::class, 'options']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');

// Routes protégées par Sanctum (token Bearer)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'show']);
    Route::put('/user', [AuthController::class, 'update']);
    Route::put('/user/password', [AuthController::class, 'updatePassword']);
});

/*
|--------------------------------------------------------------------------
| Fin du bloc authentification
|--------------------------------------------------------------------------
*/
