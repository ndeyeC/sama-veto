<?php

/*
|--------------------------------------------------------------------------
| Calendrier préventif généré à l'ajout d'un animal
|--------------------------------------------------------------------------
|
| Pour chaque espèce : les actes planifiés automatiquement, avec le nombre
| de jours après l'enregistrement de l'animal.
|
| ⚠ PROPOSITION À FAIRE VALIDER PAR LE PORTEUR DU PROJET (ingénieur
| d'élevage) : ce sont des valeurs d'exemple pour faire fonctionner les
| statuts « Urgent / Bientôt / À jour ». Il suffit de modifier ce fichier.
|
*/

return [
    'bovin' => [
        ['acte' => 'Vaccin Pasteurellose', 'jours' => 30],
        ['acte' => 'Vaccin Dermatose nodulaire', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 60],
    ],
    'ovin' => [
        ['acte' => 'Vaccin Peste des petits ruminants (PPR)', 'jours' => 30],
        ['acte' => 'Vaccin Pasteurellose', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 60],
    ],
    'caprin' => [
        ['acte' => 'Vaccin Peste des petits ruminants (PPR)', 'jours' => 30],
        ['acte' => 'Vaccin Pasteurellose', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 60],
    ],
    'volaille' => [
        ['acte' => 'Vaccin Newcastle', 'jours' => 7],
        ['acte' => 'Vaccin Gumboro', 'jours' => 14],
    ],
    'equin' => [
        ['acte' => 'Vaccin Peste équine', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 60],
    ],
    'canin' => [
        ['acte' => 'Vaccin Rage', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 30],
    ],
    'felin' => [
        ['acte' => 'Vaccin Typhus / Coryza', 'jours' => 30],
        ['acte' => 'Déparasitage', 'jours' => 30],
    ],
    'porcin' => [
        ['acte' => 'Déparasitage', 'jours' => 30],
        ['acte' => 'Visite sanitaire', 'jours' => 90],
    ],
];
