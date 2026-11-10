<?php

/*
|--------------------------------------------------------------------------
| Données métier Sama Veto (inscription)
|--------------------------------------------------------------------------
| Ces listes sont envoyées à Flutter par GET /api/auth/options :
| elles ne sont donc jamais écrites en dur dans l'application mobile.
*/

return [

    'regions' => ['Dakar', 'Thiès', 'Saint-Louis', 'Kaolack', 'Ziguinchor', 'Autre'],

    'roles' => [
        'eleveur' => [
            'label' => 'Éleveur',
            'emoji' => '👨‍🌾',
            'description' => 'Je gère mon troupeau et je suis la santé de mes animaux.',
        ],
        'proprietaire' => [
            'label' => 'Propriétaire',
            'emoji' => '🐾',
            'description' => 'Je possède un ou plusieurs animaux et je veux les suivre.',
        ],
        'veterinaire' => [
            'label' => 'Vétérinaire',
            'emoji' => '👨‍⚕️',
            'description' => 'J’assure les consultations et le suivi sanitaire des animaux.',
        ],
        'agent_epidemio' => [
            'label' => 'Agent épidémio',
            'emoji' => '🔬',
            'description' => 'Je surveille les alertes et les épidémies animales.',
        ],
    ],

];
