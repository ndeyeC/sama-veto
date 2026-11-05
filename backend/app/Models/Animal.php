<?php

namespace App\Models;

use Database\Factories\AnimalFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Animal extends Model
{
    /** @use HasFactory<AnimalFactory> */
    use HasFactory;

    public const ESPECES = ['bovin', 'ovin', 'caprin', 'volaille', 'equin', 'chien', 'chat', 'autre'];

    public const SEXES = ['male', 'femelle'];

    protected $fillable = [
        'nom',
        'espece',
        'race',
        'sexe',
        'date_naissance',
        'poids',
        'couleur',
        'numero_identification',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'date_naissance' => 'date:Y-m-d',
            'poids' => 'float',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
