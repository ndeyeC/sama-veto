<?php

namespace App\Http\Controllers;

use App\Http\Requests\AnimalRequest;
use App\Models\Animal;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Gestion des animaux de l'utilisateur connecté (CRUD).
 * Toutes les routes sont protégées par auth:sanctum : chacun ne voit que ses animaux.
 */
class AnimalController extends Controller
{
    /**
     * GET /api/animals?espece=bovin&search=...
     */
    public function index(Request $request): JsonResponse
    {
        $animals = $request->user()->animals()
            ->when($request->filled('espece'), fn ($q) => $q->where('espece', $request->query('espece')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.$request->query('search').'%';
                $q->where(fn ($q) => $q->where('nom', 'like', $term)
                    ->orWhere('race', 'like', $term)
                    ->orWhere('numero_identification', 'like', $term));
            })
            ->latest()
            ->get();

        return response()->json(['data' => $animals]);
    }

    /**
     * GET /api/animals/stats : nombre d'animaux par espèce.
     */
    public function stats(Request $request): JsonResponse
    {
        $parEspece = $request->user()->animals()
            ->selectRaw('espece, count(*) as total')
            ->groupBy('espece')
            ->pluck('total', 'espece')
            ->map(fn ($n) => (int) $n);

        return response()->json([
            'data' => [
                'total' => $parEspece->sum(),
                'par_espece' => $parEspece,
            ],
        ]);
    }

    /**
     * POST /api/animals
     */
    public function store(AnimalRequest $request): JsonResponse
    {
        $animal = $request->user()->animals()->create($request->validated());

        return response()->json([
            'message' => 'Animal enregistré avec succès.',
            'data' => $animal,
        ], 201);
    }

    /**
     * GET /api/animals/{animal}
     */
    public function show(Request $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        return response()->json(['data' => $animal]);
    }

    /**
     * PUT/PATCH /api/animals/{animal}
     */
    public function update(AnimalRequest $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        $animal->update($request->validated());

        return response()->json([
            'message' => 'Animal modifié avec succès.',
            'data' => $animal->fresh(),
        ]);
    }

    /**
     * DELETE /api/animals/{animal}
     */
    public function destroy(Request $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        $animal->delete();

        return response()->json(['message' => 'Animal supprimé avec succès.']);
    }

    private function verifierProprietaire(Request $request, Animal $animal): void
    {
        abort_if($animal->user_id !== $request->user()->id, 404, 'Animal introuvable.');
    }
}
