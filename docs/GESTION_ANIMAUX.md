# Onglet Animaux — carnet de santé (BA)

Branche : `feature/gestion-animaux`. Correspond aux sections **3.3 et 3.4** du cahier des charges (`sama-veto-specs`), plus les règles 1 et 4 (persistance, hors ligne) pour cet onglet.

## Ce qui est fait

| Cahier des charges | Où |
|---|---|
| 8 espèces : Bovin, Ovin, Caprin, Canin, Volaille, Équin, Félin, Porcin | `Animal::ESPECES` / `Animal.especes` |
| 3 compteurs : total / à planifier / urgences | `animals_page.dart`, `GET /api/animals/stats` |
| Carte : emoji, nom, race/âge, barre % santé, badge ⚠ Urgent / ⏰ Bientôt / ✓ À jour | `animal_widgets.dart` |
| Bouton « + Ajouter un animal » | `animals_page.dart` |
| Carnet : grand emoji, nom, race · sexe · naissance, historique (✓ fait / ! en retard), bouton rouge Supprimer avec confirmation | `animal_detail_page.dart` |
| Formulaire : grille de 8 icônes, nom*, race, sexe, mois + année de naissance, « Enregistrer → » | `animal_form_page.dart` |
| Statut calculé : Urgent (acte en retard) / Bientôt (≤ 7 jours) / À jour | `Animal::getStatutSanteAttribute` |
| % de couverture vaccinale | `Animal::getCouvertureAttribute` (actes faits / actes dus) |
| Premier événement automatique « ✓ Enregistrement initial — date du jour » | `Animal::booted()` |
| Suppression irréversible avec confirmation | carnet + `DELETE /api/animals/{id}` |
| Hors ligne : consultation des animaux et des carnets (test 4) | cache `shared_preferences` dans `animal_service.dart` |
| Hors ligne : ajout d'un animal, synchronisé à la reconnexion (test 7) | file d'attente dans `animal_service.dart` |
| Indicateur réseau visible | `BandeauHorsLigne` |
| Données côté serveur (MySQL), chacun ne voit que ses animaux | `auth:sanctum` + contrôle propriétaire |

En plus (optionnel, replié dans le formulaire) : poids, couleur, n° d'identification, notes. Dans le carnet, toucher un acte prévu permet de le marquer comme fait.

## API

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/api/animals` | Mes animaux, avec `statut_sante`, `couverture` et `health_events` |
| GET | `/api/animals/stats` | `total`, `a_planifier`, `urgences`, `par_espece` |
| POST | `/api/animals` | Ajouter (crée aussi l'enregistrement initial et le calendrier préventif) |
| GET / PUT / DELETE | `/api/animals/{id}` | Voir / modifier / supprimer |
| POST | `/api/animals/{id}/events` | Ajouter un acte au carnet (réutilisable par le profil vétérinaire) |
| PATCH | `/api/animals/{id}/events/{event}/fait` | Marquer un acte comme fait |

Tables : `animals`, `health_events` (acte, type, date_prevue, date_realisee).

## À valider par le porteur de projet

`backend/config/vaccins.php` contient le **calendrier préventif généré à l'ajout d'un animal** (ex. PPR pour ovins/caprins, Newcastle pour volaille). Ce sont des valeurs d'exemple pour que les statuts fonctionnent : à faire valider/corriger par Fallou, il suffit de modifier ce fichier.

## Points de coordination avec l'équipe

- **Auth** : le jeton doit être enregistré avec `StorageService().saveToken(...)`. J'ai ajouté `HasApiTokens` dans `User.php`. À l'inscription d'un éleveur, le cahier des charges demande des « animaux d'exemple » : `AnimalSeeder` montre comment les créer.
- **Rôles (règle 3)** : quand la colonne `role` existera dans `users`, il faudra limiter `/api/animals` aux éleveurs/propriétaires.
- **Navigation** : `AnimalsPage` est prête à être mise dans l'onglet « 🐄 Animaux » de la barre du bas.
- **Tableau de bord / alertes** : `GET /api/animals/stats` et les `health_events` fournissent les données (compteurs, vaccins en retard / à venir).

## Lancer en local avec MySQL

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
# Dans .env : DB_CONNECTION=mysql, DB_DATABASE=sama_veto, DB_USERNAME=root, DB_PASSWORD=...
php artisan migrate
php artisan db:seed --class=AnimalSeeder   # 4 animaux d'exemple (compte demo@samaveto.sn / password)
php artisan serve

cd ../frontend
flutter pub get
flutter run -d chrome
```

Tests : `cd backend && php artisan test` (14 tests).

## Temporaire, à retirer après la fusion de l'authentification

`POST /api/dev/token` (seulement si `APP_ENV=local`) et le bouton « Tester avec le compte démo » (seulement en mode debug). À supprimer : le bloc dans `routes/api.php`, `connexionDemo()` dans `animal_service.dart`, le bouton dans `animals_page.dart`, `devToken` dans `api_constants.dart`.
