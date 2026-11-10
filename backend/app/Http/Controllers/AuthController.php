<?php

namespace App\Http\Controllers;

use App\Models\ActivityLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;

class AuthController extends Controller
{
    /** Numéro au format international sénégalais : +221 suivi de 9 chiffres. */
    private const PHONE_REGEX = '/^\+221[0-9]{9}$/';

    /**
     * Listes pour le formulaire d'inscription (régions et profils).
     * GET /api/auth/options
     */
    public function options(): JsonResponse
    {
        $roles = collect(config('sama_veto.roles'))
            ->map(fn (array $role, string $key) => ['key' => $key] + $role)
            ->values();

        return response()->json([
            'regions' => config('sama_veto.regions'),
            'roles' => $roles,
        ]);
    }

    /**
     * Inscription : crée le compte et connecte immédiatement l'utilisateur.
     * POST /api/register
     */
    public function register(Request $request): JsonResponse
    {
        $this->normalizeInput($request);

        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:255'],
            'phone' => ['required', 'string', 'regex:'.self::PHONE_REGEX, 'unique:users,phone'],
            'region' => ['required', 'string', Rule::in(config('sama_veto.regions'))],
            'role' => ['required', 'string', Rule::in(array_keys(config('sama_veto.roles')))],
            'password' => ['required', 'string', 'min:6', 'max:128', 'confirmed'],
        ], $this->messages(), $this->attributes());

        $user = User::create($data);

        $this->initializeRoleData($user);
        $this->log($user, ActivityLog::TYPE_REGISTER);

        return response()->json([
            'message' => 'Compte créé avec succès.',
            'user' => $user,
            'token' => $user->createToken('sama-veto-app')->plainTextToken,
        ], 201);
    }

    /**
     * Connexion par téléphone + mot de passe : retourne un token Sanctum et le rôle.
     * POST /api/login
     */
    public function login(Request $request): JsonResponse
    {
        $this->normalizeInput($request);

        $credentials = $request->validate([
            'phone' => ['required', 'string'],
            'password' => ['required', 'string'],
        ], $this->messages(), $this->attributes());

        $user = User::where('phone', $credentials['phone'])->first();

        // Même message que le numéro existe ou non : on ne dit pas lequel des deux est faux.
        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            return response()->json([
                'message' => 'Numéro de téléphone ou mot de passe incorrect.',
            ], 401);
        }

        $this->log($user, ActivityLog::TYPE_LOGIN);

        return response()->json([
            'message' => 'Connexion réussie.',
            'user' => $user,
            'token' => $user->createToken('sama-veto-app')->plainTextToken,
        ]);
    }

    /**
     * Déconnexion : révoque uniquement le token utilisé pour cette requête.
     * POST /api/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $token = $request->user()->currentAccessToken();

        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        }

        return response()->json(['message' => 'Déconnexion réussie.']);
    }

    /**
     * Profil de l'utilisateur connecté (sert aussi à la reconnexion automatique).
     * GET /api/user
     */
    public function show(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()]);
    }

    /**
     * Mise à jour du profil (nom, téléphone, région). Le rôle est DÉFINITIF : jamais modifiable ici.
     * PUT /api/user
     */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->normalizeInput($request);

        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:255'],
            'phone' => ['required', 'string', 'regex:'.self::PHONE_REGEX, Rule::unique('users', 'phone')->ignore($user->id)],
            'region' => ['required', 'string', Rule::in(config('sama_veto.regions'))],
        ], $this->messages(), $this->attributes());

        $user->update($data);

        return response()->json([
            'message' => 'Profil mis à jour.',
            'user' => $user->fresh(),
        ]);
    }

    /**
     * Changement de mot de passe. Les autres appareils sont déconnectés.
     * PUT /api/user/password
     */
    public function updatePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:6', 'max:128', 'confirmed', 'different:current_password'],
        ], $this->messages(), $this->attributes());

        $user = $request->user();

        if (! Hash::check($data['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Le mot de passe actuel est incorrect.'],
            ]);
        }

        $user->update(['password' => $data['password']]);

        $current = $user->currentAccessToken();
        $user->tokens()
            ->when($current instanceof PersonalAccessToken, fn ($query) => $query->where('id', '!=', $current->id))
            ->delete();

        return response()->json(['message' => 'Mot de passe modifié avec succès.']);
    }

    /**
     * Données de départ selon le rôle (ex. animaux d'exemple pour un éleveur).
     * À brancher avec la fonctionnalité « gestion des animaux » (branche d'un autre membre) :
     * à coordonner avant d'y écrire quoi que ce soit.
     */
    private function initializeRoleData(User $user): void
    {
        // if ($user->role === 'eleveur') { ... }
    }

    private function log(User $user, string $type): void
    {
        ActivityLog::create([
            'user_id' => $user->id,
            'user_name' => $user->name,
            'role' => $user->role,
            'type' => $type,
        ]);
    }

    /** Téléphone ramené au format +221XXXXXXXXX (espaces, points, tirets retirés). */
    private function normalizeInput(Request $request): void
    {
        $phone = $request->input('phone');

        if (! is_string($phone)) {
            return;
        }

        $clean = preg_replace('/[^\d+]/', '', $phone) ?? '';

        if (str_starts_with($clean, '+')) {
            $clean = '+'.str_replace('+', '', substr($clean, 1));
        } elseif (str_starts_with($clean, '00221')) {
            $clean = '+'.substr($clean, 2);
        } elseif (preg_match('/^221[0-9]{9}$/', $clean)) {
            $clean = '+'.$clean;
        } elseif (preg_match('/^[0-9]{9}$/', $clean)) {
            $clean = '+221'.$clean;
        }

        $request->merge(['phone' => $clean]);
    }

    /** Messages d'erreur en français. */
    private function messages(): array
    {
        return [
            'required' => 'Le champ :attribute est obligatoire.',
            'string' => 'Le champ :attribute n’est pas valide.',
            'min.string' => 'Le champ :attribute doit contenir au moins :min caractères.',
            'max.string' => 'Le champ :attribute ne doit pas dépasser :max caractères.',
            'confirmed' => 'La confirmation du mot de passe ne correspond pas.',
            'different' => 'Le nouveau mot de passe doit être différent de l’actuel.',
            'phone.regex' => 'Le numéro doit être au format +221 77 123 45 67.',
            'phone.unique' => 'Ce numéro de téléphone est déjà utilisé.',
            'region.in' => 'Veuillez choisir une région valide.',
            'role.in' => 'Veuillez choisir un profil valide.',
        ];
    }

    private function attributes(): array
    {
        return [
            'name' => 'nom',
            'phone' => 'numéro de téléphone',
            'region' => 'région',
            'role' => 'profil',
            'password' => 'mot de passe',
            'current_password' => 'mot de passe actuel',
        ];
    }
}
