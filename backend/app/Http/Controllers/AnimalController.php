<?php

namespace App\Http\Controllers;

use App\Http\Requests\AnimalRequest;
use App\Models\Animal;
use App\Models\HealthEvent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * Onglet « Animaux » (carnet de santé) de l'utilisateur connecté.
 * Toutes les routes sont protégées par auth:sanctum : chacun ne voit que ses animaux.
 */
class AnimalController extends Controller
{
    /**
     * GET /api/animals?espece=bovin&search=...
     * Chaque animal est renvoyé avec son historique (health_events), son statut et sa couverture,
     * ce qui permet à l'application de tout garder en cache pour le mode hors ligne.
     */
    public function index(Request $request): JsonResponse
    {
        $animals = $request->user()->animals()
            ->with('healthEvents')
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
     * GET /api/animals/stats : les 3 compteurs (total / à planifier / urgences) + répartition par espèce.
     */
    public function stats(Request $request): JsonResponse
    {
        $animals = $request->user()->animals()->with('healthEvents')->get();

        return response()->json([
            'data' => [
                'total' => $animals->count(),
                'a_planifier' => $animals->where('statut_sante', 'bientot')->count(),
                'urgences' => $animals->where('statut_sante', 'urgent')->count(),
                'par_espece' => $animals->countBy('espece'),
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
            'data' => $animal->load('healthEvents'),
        ], 201);
    }

    /**
     * GET /api/animals/{animal}
     */
    public function show(Request $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        return response()->json(['data' => $animal->load('healthEvents')]);
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
            'data' => $animal->fresh()->load('healthEvents'),
        ]);
    }

    /**
     * DELETE /api/animals/{animal} (irréversible, l'historique est supprimé avec)
     */
    public function destroy(Request $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        $animal->delete();

        return response()->json(['message' => 'Animal supprimé avec succès.']);
    }

    /**
     * POST /api/animals/{animal}/events : ajouter un acte au carnet.
     * (Le profil vétérinaire pourra réutiliser cette route pour ses patients.)
     */
    public function ajouterEvenement(Request $request, Animal $animal): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);

        $data = $request->validate([
            'acte' => ['required', 'string', 'max:150'],
            'type' => ['required', Rule::in(HealthEvent::TYPES)],
            'date_prevue' => ['required', 'date'],
            'date_realisee' => ['nullable', 'date', 'before_or_equal:today'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ], [
            'acte.required' => 'Le nom de l\'acte est obligatoire.',
            'date_prevue.required' => 'La date est obligatoire.',
        ]);

        $event = $animal->healthEvents()->create($data + ['created_by' => $request->user()->id]);

        return response()->json([
            'message' => 'Acte ajouté au carnet.',
            'data' => $event,
            'animal' => $animal->fresh()->load('healthEvents'),
        ], 201);
    }

    /**
     * PATCH /api/animals/{animal}/events/{event}/fait : marquer un acte comme réalisé (aujourd'hui).
     */
    public function marquerFait(Request $request, Animal $animal, HealthEvent $event): JsonResponse
    {
        $this->verifierProprietaire($request, $animal);
        abort_if($event->animal_id !== $animal->id, 404, 'Acte introuvable.');

        $event->update(['date_realisee' => today()]);

        return response()->json([
            'message' => 'Acte marqué comme fait.',
            'animal' => $animal->fresh()->load('healthEvents'),
        ]);
    }

    private function verifierProprietaire(Request $request, Animal $animal): void
    {
        abort_if($animal->user_id !== $request->user()->id, 404, 'Animal introuvable.');
    }
}
