<?php

namespace App\Http\Controllers;

use App\Models\ReferralLink;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class ReferralRedirectController extends Controller
{
    public function handle($code)
    {
        return view('referral', [
            'token' => $code,
        ]);
    }
}