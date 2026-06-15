<?php
$LOGDIR = __DIR__ . '/data';
$LOG = $LOGDIR . '/visits.ndjson';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    http_response_code(405);
    header('Allow: POST');
    exit;
}

$ua = $_SERVER['HTTP_USER_AGENT'] ?? '';
if (preg_match('/bot|crawl|spider|slurp|preview|facebookexternalhit|curl|wget|headless/i', $ua)) {
    http_response_code(204);
    exit;
}

$ip = $_SERVER['REMOTE_ADDR'] ?? '';
$salt = gmdate('Y-m-d');
$vid = substr(hash('sha256', $ip . '|' . $ua . '|' . $salt), 0, 16);
$maskedIp = preg_replace('/\.\d+$/', '.0', $ip);

$page = substr($_POST['p'] ?? '', 0, 200);
$ref = substr($_POST['r'] ?? '', 0, 200);
$utm_source = substr($_POST['utm_source'] ?? '', 0, 80);
$utm_medium = substr($_POST['utm_medium'] ?? '', 0, 80);
$utm_campaign = substr($_POST['utm_campaign'] ?? '', 0, 80);

if (!is_dir($LOGDIR)) {
    @mkdir($LOGDIR, 0755, true);
}

$entry = [
    'ts' => gmdate('c'),
    'vid' => $vid,
    'ip' => $maskedIp,
    'ua' => substr($ua, 0, 180),
    'ref' => $ref,
    'page' => $page,
    'utm_source' => $utm_source,
    'utm_medium' => $utm_medium,
    'utm_campaign' => $utm_campaign,
];

$line = json_encode($entry, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n";
$fh = @fopen($LOG, 'a');
if ($fh) {
    if (flock($fh, LOCK_EX)) {
        fwrite($fh, $line);
        flock($fh, LOCK_UN);
    }
    fclose($fh);
}

http_response_code(204);
header('Cache-Control: no-store');
exit;
