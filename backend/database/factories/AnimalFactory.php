<?php

namespace Database\Factories;

use App\Models\Animal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Animal>
 */
class AnimalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'nom' => fake()->firstName(),
            'espece' => fake()->randomElement(Animal::ESPECES),
            'race' => fake()->optional()->word(),
            'sexe' => fake()->randomElement(Animal::SEXES),
            'date_naissance' => fake()->optional()->dateTimeBetween('-8 years', '-1 month')?->format('Y-m-d'),
            'poids' => fake()->optional()->randomFloat(1, 1, 600),
            'couleur' => fake()->optional()->safeColorName(),
            'numero_identification' => fake()->optional()->bothify('SN-####-??'),
            'notes' => null,
        ];
    }
}
