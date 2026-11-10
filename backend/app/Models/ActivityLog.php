<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['user_id', 'user_name', 'role', 'type'])]
class ActivityLog extends Model
{
    public const UPDATED_AT = null;

    public const TYPE_REGISTER = 'inscription';

    public const TYPE_LOGIN = 'connexion';
}
