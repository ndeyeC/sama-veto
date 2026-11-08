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

    public function test_enregistrement_initial_et_calendrier_generes(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $res = $this->postJson('/api/animals', ['nom' => 'Pinto', 'espece' => 'volaille', 'sexe' => 'femelle'])
            ->assertCreated()
            ->assertJsonPath('data.statut_sante', 'bientot') // Newcastle dans 7 jours
            ->assertJsonPath('data.couverture', 100);

        $events = collect($res->json('data.health_events'));
        $this->assertTrue($events->contains(fn ($e) => $e['acte'] === 'Enregistrement initial' && $e['statut'] === 'fait'));
        $this->assertCount(1 + count(config('vaccins.volaille')), $events);
    }

    public function test_statut_urgent_couverture_et_marquer_fait(): void
    {
        $moi = User::factory()->create();
        $animal = Animal::factory()->create(['user_id' => $moi->id, 'espece' => 'bovin']);
        Sanctum::actingAs($moi);

        $res = $this->postJson("/api/animals/{$animal->id}/events", [
            'acte' => 'Vaccin oublié', 'type' => 'vaccin', 'date_prevue' => today()->subDays(3)->toDateString(),
        ])->assertCreated()
            ->assertJsonPath('animal.statut_sante', 'urgent')
            ->assertJsonPath('animal.couverture', 50); // 1 fait (enregistrement) sur 2 dus

        $this->getJson('/api/animals/stats')->assertJsonPath('data.urgences', 1);

        $eventId = $res->json('data.id');
        $this->patchJson("/api/animals/{$animal->id}/events/{$eventId}/fait")
            ->assertOk()
            ->assertJsonPath('animal.statut_sante', 'a_jour')
            ->assertJsonPath('animal.couverture', 100);
    }

    public function test_pas_d_acte_sur_l_animal_d_un_autre(): void
    {
        $autre = Animal::factory()->create();
        Sanctum::actingAs(User::factory()->create());

        $this->postJson("/api/animals/{$autre->id}/events", [
            'acte' => 'X', 'type' => 'vaccin', 'date_prevue' => today()->toDateString(),
        ])->assertNotFound();
    }

    public function test_les_8_especes_du_cahier_des_charges(): void
    {
        Sanctum::actingAs(User::factory()->create());

        foreach (['bovin', 'ovin', 'caprin', 'canin', 'volaille', 'equin', 'felin', 'porcin'] as $espece) {
            $this->postJson('/api/animals', ['nom' => $espece, 'espece' => $espece, 'sexe' => 'male'])->assertCreated();
        }
        $this->postJson('/api/animals', ['nom' => 'X', 'espece' => 'chien', 'sexe' => 'male'])
            ->assertJsonValidationErrors('espece');
    }
}
