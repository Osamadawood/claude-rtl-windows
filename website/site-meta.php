<?php
declare(strict_types=1);

/**
 * Open Graph / Facebook — App ID من Meta for Developers
 * https://developers.facebook.com/apps/ → التطبيق → Settings → Basic → App ID
 *
 * أنشئ تطبيقًا من نوع «Other» أو «Business»، أضف نطاق claude-rtl.grwlab.net،
 * ثم الصق App ID هنا (أرقام فقط).
 */
const FB_APP_ID = '1016482080740557';

function fb_app_id_meta(): string
{
    if (FB_APP_ID === '' || !ctype_digit(FB_APP_ID)) {
        return '';
    }

    return '<meta property="fb:app_id" content="' . htmlspecialchars(FB_APP_ID, ENT_QUOTES, 'UTF-8') . '">' . "\n    ";
}
