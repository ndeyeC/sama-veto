<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Table des animaux : chaque animal appartient à un utilisateur (éleveur / propriétaire).
     */
    public function up(): void
    {
        Schema::create('animals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('nom', 100);
            $table->string('espece', 30); // bovin, ovin, caprin, volaille, equin, chien, chat, autre
            $table->string('race', 100)->nullable();
            $table->string('sexe', 10); // male, femelle
            $table->date('date_naissance')->nullable();
            $table->decimal('poids', 8, 2)->nullable(); // en kg
            $table->string('couleur', 50)->nullable();
            $table->string('numero_identification', 50)->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'numero_identification']);
            $table->index(['user_id', 'espece']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('animals');
    }
};
