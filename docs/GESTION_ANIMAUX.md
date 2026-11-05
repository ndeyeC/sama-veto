# Gestion des animaux (BA)

Branche : `feature/gestion-animaux` (partie de `develop`).

## Backend (Laravel)

| Méthode | Route | Rôle |
|---|---|---|
| GET | `/api/animals?espece=bovin&search=...` | Liste de **mes** animaux (filtre + recherche) |
| GET | `/api/animals/stats` | Total et nombre par espèce |
| POST | `/api/animals` | Ajouter un animal |
| GET | `/api/animals/{id}` | Détail d'un animal |
| PUT | `/api/animals/{id}` | Modifier |
| DELETE | `/api/animals/{id}` | Supprimer |

Toutes ces routes sont protégées par `auth:sanctum` (jeton Bearer). Un utilisateur ne voit et ne modifie que ses propres animaux (sinon : 404).

Champs : `nom`*, `espece`* (`bovin, ovin, caprin, volaille, equin, chien, chat, autre`), `sexe`* (`male, femelle`), `race`, `date_naissance` (AAAA-MM-JJ), `poids` (kg), `couleur`, `numero_identification` (unique par utilisateur), `notes`.

Fichiers :
- `database/migrations/2026_11_05_120000_create_animals_table.php`
- `app/Models/Animal.php` (+ relation `animals()` et trait `HasApiTokens` dans `User`)
- `app/Http/Requests/AnimalRequest.php` (validation, messages en français)
- `app/Http/Controllers/AnimalController.php`
- `database/factories/AnimalFactory.php`, `database/seeders/AnimalSeeder.php`
- `tests/Feature/AnimalTest.php` (8 tests)

## Frontend (Flutter)

- `lib/models/animal.dart`
- `lib/services/animal_service.dart`
- `lib/screens/animals/animals_page.dart` : liste, recherche, filtre par espèce, statistiques, détail, suppression
- `lib/screens/animals/animal_form_page.dart` : ajout / modification avec affichage des erreurs renvoyées par Laravel
- Route `/animals` dans `main.dart` ; la carte « Gestion des animaux » de l'accueil ouvre cet écran.

## Lancer en local avec MySQL

```bash
cd backend
cp .env.example .env
php artisan key:generate
# Dans .env :
# DB_CONNECTION=mysql
# DB_HOST=127.0.0.1
# DB_PORT=3306
# DB_DATABASE=sama_veto
# DB_USERNAME=root
# DB_PASSWORD=
php artisan migrate
php artisan db:seed --class=AnimalSeeder   # optionnel : 4 animaux d'exemple (compte demo@samaveto.sn / password)
php artisan serve

cd ../frontend
flutter pub get
flutter run -d chrome
```

Tests : `cd backend && php artisan test`

## Temporaire, à retirer après la fusion de l'authentification

En attendant l'écran de connexion, `POST /api/dev/token` (actif seulement si `APP_ENV=local`) renvoie un jeton du compte démo. Dans Flutter, le bouton « Tester avec le compte démo » (visible seulement en mode debug) l'utilise. Une fois l'auth fusionnée, supprimer ce bloc dans `routes/api.php`, `connexionDemo()` dans `animal_service.dart`, le bouton dans `animals_page.dart` et `devToken` dans `api_constants.dart`.

Note pour l'équipe auth : le token doit être enregistré avec `StorageService().saveToken(...)` (clé `auth_token`), c'est là que la gestion des animaux le lit.
