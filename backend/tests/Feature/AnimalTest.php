<?php

namespace Tests\Feature;

use App\Models\Animal;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AnimalTest extends TestCase
{
    use RefreshDatabase;

    public function test_un_invite_ne_peut_pas_voir_les_animaux(): void
    {
        $this->getJson('/api/animals')->assertUnauthorized();
    }

    public function test_lister_uniquement_mes_animaux(): void
    {
        $moi = User::factory()->create();
        Animal::factory()->count(3)->create(['user_id' => $moi->id]);
        Animal::factory()->count(2)->create(); // animaux d'un autre utilisateur

        Sanctum::actingAs($moi);

        $this->getJson('/api/animals')->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_creer_un_animal(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/animals', [
            'nom' => 'Bouba',
            'espece' => 'bovin',
            'race' => 'Zébu Gobra',
            'sexe' => 'femelle',
            'date_naissance' => '2023-04-10',
            'poids' => 320.5,
            'numero_identification' => 'SN-0001',
        ])->assertCreated()
            ->assertJsonPath('data.nom', 'Bouba')
            ->assertJsonPath('data.date_naissance', '2023-04-10');

        $this->assertDatabaseHas('animals', ['nom' => 'Bouba', 'espece' => 'bovin']);
    }

    public function test_validation_a_la_creation(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/animals', ['espece' => 'dragon'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['nom', 'espece', 'sexe']);
    }

    public function test_numero_identification_unique_par_utilisateur(): void
    {
        $moi = User::factory()->create();
        Animal::factory()->create(['user_id' => $moi->id, 'numero_identification' => 'SN-42']);
        Animal::factory()->create(['numero_identification' => 'SN-43']); // autre utilisateur

        Sanctum::actingAs($moi);
        $base = ['nom' => 'X', 'espece' => 'ovin', 'sexe' => 'male'];

        $this->postJson('/api/animals', $base + ['numero_identification' => 'SN-42'])
            ->assertJsonValidationErrors('numero_identification');
        $this->postJson('/api/animals', $base + ['numero_identification' => 'SN-43'])
            ->assertCreated();
    }

    public function test_modifier_et_supprimer_mon_animal(): void
    {
        $moi = User::factory()->create();
        $animal = Animal::factory()->create(['user_id' => $moi->id, 'numero_identification' => 'SN-7']);
        Sanctum::actingAs($moi);

        $this->putJson("/api/animals/{$animal->id}", [
            'nom' => 'Nouveau nom', 'espece' => 'caprin', 'sexe' => 'male', 'numero_identification' => 'SN-7',
        ])->assertOk()->assertJsonPath('data.nom', 'Nouveau nom');

        $this->deleteJson("/api/animals/{$animal->id}")->assertOk();
        $this->assertDatabaseMissing('animals', ['id' => $animal->id]);
    }

    public function test_impossible_de_toucher_l_animal_d_un_autre(): void
    {
        $autre = Animal::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson("/api/animals/{$autre->id}")->assertNotFound();
        $this->deleteJson("/api/animals/{$autre->id}")->assertNotFound();
        $this->assertDatabaseHas('animals', ['id' => $autre->id]);
    }

    public function test_filtre_et_statistiques(): void
    {
        $moi = User::factory()->create();
        Animal::factory()->count(2)->create(['user_id' => $moi->id, 'espece' => 'bovin']);
        Animal::factory()->create(['user_id' => $moi->id, 'espece' => 'ovin', 'nom' => 'Sakho']);
        Sanctum::actingAs($moi);

        $this->getJson('/api/animals?espece=bovin')->assertJsonCount(2, 'data');
        $this->getJson('/api/animals?search=Sakh')->assertJsonCount(1, 'data');
        $this->getJson('/api/animals/stats')
            ->assertJsonPath('data.total', 3)
            ->assertJsonPath('data.par_espece.bovin', 2);
    }
}
