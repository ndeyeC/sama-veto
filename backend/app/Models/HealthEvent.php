<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Un acte du carnet de santé (vaccin, traitement, visite...).
 */
class HealthEvent extends Model
{
    public const TYPES = ['enregistrement', 'vaccin', 'traitement', 'visite', 'autre'];

    protected $fillable = ['acte', 'type', 'date_prevue', 'date_realisee', 'notes', 'created_by'];

    protected $appends = ['statut'];

    protected function casts(): array
    {
        return [
            'date_prevue' => 'date:Y-m-d',
            'date_realisee' => 'date:Y-m-d',
        ];
    }

    public function animal(): BelongsTo
    {
        return $this->belongsTo(Animal::class);
    }

    /**
     * fait | en_retard | bientot (dans 7 jours ou moins) | prevu
     */
    public function getStatutAttribute(): string
    {
        if ($this->date_realisee !== null) {
            return 'fait';
        }

        $today = today();
        if ($this->date_prevue->lt($today)) {
            return 'en_retard';
        }

        return $this->date_prevue->lte($today->copy()->addDays(7)) ? 'bientot' : 'prevu';
    }
}
