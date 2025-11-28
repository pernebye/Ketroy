<?php

use App\Http\Controllers\ReferralRedirectController;
use Illuminate\Support\Facades\Route;

Route::get('/r/{code}', [ReferralRedirectController::class, 'handle']);
