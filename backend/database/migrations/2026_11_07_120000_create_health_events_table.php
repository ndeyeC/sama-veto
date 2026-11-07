<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Carnet de santé : historique des actes (vaccins, traitements, visites...) d'un animal.
     */
    public function up(): void
    {
        Schema::create('health_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('animal_id')->constrained()->cascadeOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('acte', 150);            // ex. « Vaccin PPR »
            $table->string('type', 30);             // enregistrement, vaccin, traitement, visite, autre
            $table->date('date_prevue');            // date à laquelle l'acte est prévu
            $table->date('date_realisee')->nullable(); // null = pas encore fait
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['animal_id', 'date_prevue']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('health_events');
    }
};
