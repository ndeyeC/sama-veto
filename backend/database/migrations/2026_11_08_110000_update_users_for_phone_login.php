<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * La connexion se fait par numéro de téléphone : l'email devient facultatif
     * et on ajoute téléphone (unique), région et rôle.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
            $table->string('phone', 20)->nullable()->unique()->after('name');
            $table->string('region', 50)->nullable()->after('phone');
            $table->string('role', 30)->nullable()->after('region');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['phone']);
            $table->dropColumn(['phone', 'region', 'role']);
        });
    }
};
