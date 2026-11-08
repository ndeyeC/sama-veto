<?php

namespace App\Models;

use Database\Factories\AnimalFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Animal extends Model
{
    /** @use HasFactory<AnimalFactory> */
    use HasFactory;

    /** Les 8 espèces du cahier des charges (section 3.3). */
    public const ESPECES = ['bovin', 'ovin', 'caprin', 'canin', 'volaille', 'equin', 'felin', 'porcin'];

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

    protected $appends = ['statut_sante', 'couverture'];

    protected function casts(): array
    {
        return [
            'date_naissance' => 'date:Y-m-d',
            'poids' => 'float',
        ];
    }

    /**
     * À la création : événement « Enregistrement initial » (fait aujourd'hui)
     * + calendrier préventif de l'espèce (config/vaccins.php).
     */
    protected static function booted(): void
    {
        static::created(function (Animal $animal) {
            $today = today();

            $animal->healthEvents()->create([
                'acte' => 'Enregistrement initial',
                'type' => 'enregistrement',
                'date_prevue' => $today,
                'date_realisee' => $today,
            ]);

            foreach (config("vaccins.{$animal->espece}", []) as $acte) {
                $animal->healthEvents()->create([
                    'acte' => $acte['acte'],
                    'type' => str_starts_with($acte['acte'], 'Vaccin') ? 'vaccin' : 'traitement',
                    'date_prevue' => $today->copy()->addDays($acte['jours']),
                ]);
            }
        });
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function healthEvents(): HasMany
    {
        return $this->hasMany(HealthEvent::class)->orderByDesc('date_prevue')->orderByDesc('id');
    }

    /**
     * urgent (au moins un acte en retard) | bientot (un acte dans 7 jours ou moins) | a_jour
     */
    public function getStatutSanteAttribute(): string
    {
        $statuts = $this->healthEvents->pluck('statut');

        if ($statuts->contains('en_retard')) {
            return 'urgent';
        }

        return $statuts->contains('bientot') ? 'bientot' : 'a_jour';
    }

    /**
     * % de couverture : parmi les actes dont la date est passée ou aujourd'hui,
     * part de ceux qui ont été faits. 100 % s'il n'y a encore rien de dû.
     */
    public function getCouvertureAttribute(): int
    {
        $dus = $this->healthEvents->filter(fn (HealthEvent $e) => $e->statut === 'fait' || $e->statut === 'en_retard');

        if ($dus->isEmpty()) {
            return 100;
        }

        return (int) round(100 * $dus->where('statut', 'fait')->count() / $dus->count());
    }
}
