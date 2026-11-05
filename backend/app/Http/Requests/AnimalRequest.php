<?php

namespace App\Http\Requests;

use App\Models\Animal;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class AnimalRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Règles valables pour la création (POST) et la modification (PUT/PATCH).
     */
    public function rules(): array
    {
        $animal = $this->route('animal');
        $required = $this->isMethod('PATCH') ? 'sometimes' : 'required';

        return [
            'nom' => [$required, 'string', 'max:100'],
            'espece' => [$required, Rule::in(Animal::ESPECES)],
            'race' => ['nullable', 'string', 'max:100'],
            'sexe' => [$required, Rule::in(Animal::SEXES)],
            'date_naissance' => ['nullable', 'date', 'before_or_equal:today'],
            'poids' => ['nullable', 'numeric', 'min:0', 'max:5000'],
            'couleur' => ['nullable', 'string', 'max:50'],
            'numero_identification' => [
                'nullable', 'string', 'max:50',
                Rule::unique('animals')
                    ->where('user_id', $this->user()->id)
                    ->ignore($animal?->id),
            ],
            'notes' => ['nullable', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'nom.required' => 'Le nom de l\'animal est obligatoire.',
            'espece.required' => 'L\'espèce est obligatoire.',
            'espece.in' => 'Espèce invalide.',
            'sexe.required' => 'Le sexe est obligatoire.',
            'sexe.in' => 'Le sexe doit être « male » ou « femelle ».',
            'date_naissance.before_or_equal' => 'La date de naissance ne peut pas être dans le futur.',
            'poids.numeric' => 'Le poids doit être un nombre.',
            'numero_identification.unique' => 'Vous avez déjà un animal avec ce numéro d\'identification.',
        ];
    }
}
