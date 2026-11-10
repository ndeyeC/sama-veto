<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function payload(array $override = []): array
    {
        return array_merge([
            'name' => 'Awa Diop',
            'phone' => '+221 77 123 45 67',
            'region' => 'Dakar',
            'role' => 'eleveur',
            'password' => 'secret1',
            'password_confirmation' => 'secret1',
        ], $override);
    }

    private function createUser(array $override = []): User
    {
        return User::factory()->create(array_merge([
            'name' => 'Awa Diop',
            'phone' => '+221771234567',
            'region' => 'Dakar',
            'role' => 'eleveur',
            'password' => 'secret1',
        ], $override));
    }

    public function test_options_returns_regions_and_roles(): void
    {
        $this->getJson('/api/auth/options')
            ->assertOk()
            ->assertJsonPath('regions.0', 'Dakar')
            ->assertJsonCount(4, 'roles')
            ->assertJsonStructure(['roles' => [['key', 'label', 'emoji', 'description']]]);
    }

    public function test_user_can_register_and_is_logged_in(): void
    {
        $this->postJson('/api/register', $this->payload())
            ->assertCreated()
            ->assertJsonStructure(['message', 'token', 'user' => ['id', 'name', 'phone', 'region', 'role', 'role_label']])
            ->assertJsonPath('user.phone', '+221771234567')
            ->assertJsonMissingPath('user.password');

        $this->assertDatabaseHas('users', ['phone' => '+221771234567', 'role' => 'eleveur']);
        $this->assertDatabaseHas('activity_logs', ['user_name' => 'Awa Diop', 'role' => 'eleveur', 'type' => 'inscription']);
    }

    public function test_register_rejects_duplicate_phone(): void
    {
        $this->createUser();

        $this->postJson('/api/register', $this->payload(['phone' => '77 123 45 67']))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);
    }

    public function test_register_rejects_invalid_data(): void
    {
        $this->postJson('/api/register', [
            'name' => '',
            'phone' => '12345',
            'region' => 'Mars',
            'role' => 'admin',
            'password' => '12345',
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['name', 'phone', 'region', 'role', 'password']);
    }

    public function test_register_requires_matching_passwords(): void
    {
        $this->postJson('/api/register', $this->payload(['password_confirmation' => 'autre12']))
            ->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    public function test_user_can_login_with_phone(): void
    {
        $this->createUser();

        $this->postJson('/api/login', ['phone' => '77 123 45 67', 'password' => 'secret1'])
            ->assertOk()
            ->assertJsonStructure(['message', 'token', 'user' => ['id', 'role', 'role_label']])
            ->assertJsonPath('user.role', 'eleveur');

        $this->assertDatabaseHas('activity_logs', ['user_name' => 'Awa Diop', 'type' => 'connexion']);
    }

    public function test_login_fails_with_wrong_password_or_unknown_phone(): void
    {
        $this->createUser();

        $this->postJson('/api/login', ['phone' => '+221771234567', 'password' => 'mauvais'])
            ->assertStatus(401)
            ->assertJson(['message' => 'Numéro de téléphone ou mot de passe incorrect.']);

        $this->postJson('/api/login', ['phone' => '+221700000000', 'password' => 'secret1'])
            ->assertStatus(401)
            ->assertJson(['message' => 'Numéro de téléphone ou mot de passe incorrect.']);
    }

    public function test_profile_requires_authentication(): void
    {
        $this->getJson('/api/user')->assertUnauthorized();
    }

    public function test_user_can_view_and_update_profile_but_not_role(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->getJson('/api/user')
            ->assertOk()
            ->assertJsonPath('user.phone', '+221771234567');

        $this->withToken($token)->putJson('/api/user', [
            'name' => 'Nouveau Nom',
            'phone' => '+221 78 000 00 00',
            'region' => 'Thiès',
            'role' => 'veterinaire',
        ])->assertOk()->assertJsonPath('user.name', 'Nouveau Nom');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'phone' => '+221780000000',
            'region' => 'Thiès',
            'role' => 'eleveur',
        ]);
    }

    public function test_profile_update_cannot_take_another_users_phone(): void
    {
        $this->createUser(['phone' => '+221771111111']);
        $user = $this->createUser(['phone' => '+221772222222']);
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->putJson('/api/user', [
            'name' => $user->name,
            'phone' => '+221771111111',
            'region' => 'Dakar',
        ])->assertStatus(422)->assertJsonValidationErrors(['phone']);
    }

    public function test_logout_revokes_the_token(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->postJson('/api/logout')->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_user_can_change_password(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->putJson('/api/user/password', [
            'current_password' => 'secret1',
            'password' => 'nouveau1',
            'password_confirmation' => 'nouveau1',
        ])->assertOk();

        $this->postJson('/api/login', ['phone' => '+221771234567', 'password' => 'nouveau1'])->assertOk();
    }

    public function test_change_password_rejects_wrong_current_password(): void
    {
        $user = $this->createUser();
        $token = $user->createToken('test')->plainTextToken;

        $this->withToken($token)->putJson('/api/user/password', [
            'current_password' => 'incorrect',
            'password' => 'nouveau1',
            'password_confirmation' => 'nouveau1',
        ])->assertStatus(422)->assertJsonValidationErrors(['current_password']);
    }
}
