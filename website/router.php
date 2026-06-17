<?php

declare(strict_types=1);

/**
 * Router for PHP built-in server — mirrors website/.htaccess clean URLs locally.
 *
 * Usage:
 *   cd website && php -S localhost:8080 router.php
 */
$root = __DIR__;
$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$uri = rtrim($uri, '/') ?: '/';

$routes = [
    '/privacy' => 'privacy.html',
    '/terms' => 'terms.html',
    '/releases' => 'releases.html',
    '/download/ClaudeRTL.dmg' => 'download.php',
];

if (isset($routes[$uri])) {
    serve($root . '/' . $routes[$uri]);
    return true;
}

if ($uri === '/index.html') {
    header('Location: /', true, 301);
    exit;
}

foreach (['/privacy.html' => '/privacy', '/terms.html' => '/terms', '/releases.html' => '/releases', '/releases.php' => '/releases'] as $legacy => $target) {
    if ($uri === $legacy) {
        header('Location: ' . $target, true, 301);
        exit;
    }
}

$path = $root . $uri;
if ($uri !== '/' && is_file($path)) {
    return false;
}

if ($uri === '/') {
    serve($root . '/index.php');
    return true;
}

http_response_code(404);
serve($root . '/404.html');
return true;

function serve(string $file): void
{
    if (!is_file($file)) {
        http_response_code(404);
        echo '404 Not Found';
        return;
    }

    if (str_ends_with($file, '.php')) {
        require $file;
        return;
    }

    $ext = pathinfo($file, PATHINFO_EXTENSION);
    $types = [
        'html' => 'text/html; charset=utf-8',
        'css'  => 'text/css; charset=utf-8',
        'js'   => 'application/javascript; charset=utf-8',
        'json' => 'application/json; charset=utf-8',
        'xml'  => 'application/xml; charset=utf-8',
        'txt'  => 'text/plain; charset=utf-8',
        'svg'  => 'image/svg+xml',
        'png'  => 'image/png',
        'jpg'  => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'webp' => 'image/webp',
        'ico'  => 'image/x-icon',
    ];
    if (isset($types[$ext])) {
        header('Content-Type: ' . $types[$ext]);
    }

    readfile($file);
}
