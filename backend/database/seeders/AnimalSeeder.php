<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Quelques animaux d'exemple pour le compte démo.
 * Lancer : php artisan db:seed --class=AnimalSeeder
 */
class AnimalSeeder extends Seeder
{
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['email' => 'demo@samaveto.sn'],
            ['name' => 'Éleveur Démo', 'password' => 'password']
        );

        $animaux = [
            ['nom' => 'Bouba', 'espece' => 'bovin', 'race' => 'Zébu Gobra', 'sexe' => 'femelle', 'date_naissance' => '2022-03-15', 'poids' => 310, 'numero_identification' => 'SN-BOV-001'],
            ['nom' => 'Ndiaga', 'espece' => 'ovin', 'race' => 'Ladoum', 'sexe' => 'male', 'date_naissance' => '2023-07-02', 'poids' => 95, 'numero_identification' => 'SN-OVI-014'],
            ['nom' => 'Khady', 'espece' => 'caprin', 'race' => 'Chèvre du Sahel', 'sexe' => 'femelle', 'date_naissance' => '2024-01-20', 'poids' => 32],
            ['nom' => 'Rex', 'espece' => 'chien', 'race' => 'Berger', 'sexe' => 'male', 'date_naissance' => '2021-11-05', 'poids' => 28],
        ];

        foreach ($animaux as $a) {
            $user->animals()->firstOrCreate(['nom' => $a['nom']], $a);
        }
    }
}
