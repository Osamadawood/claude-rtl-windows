<?php
// ===== Config =====
$FILE   = __DIR__ . '/download/ClaudeRTL-1.1.0.dmg'; // مسار الملف الحقيقي
$NAME   = 'ClaudeRTL-1.1.0.dmg';                      // اسم الملف عند التحميل
$LOGDIR = __DIR__ . '/data';
$LOG    = $LOGDIR . '/downloads.ndjson';

if (!is_file($FILE)) { http_response_code(404); echo 'File not found'; exit; }

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method !== 'GET' && $method !== 'HEAD') {
    http_response_code(405);
    header('Allow: GET, HEAD');
    echo 'Method not allowed';
    exit;
}
$ua = $_SERVER['HTTP_USER_AGENT'] ?? '';
$isBot = preg_match('/bot|crawl|spider|slurp|preview|facebookexternalhit|curl|wget|headless/i', $ua);

if ($method === 'GET' && !$isBot) {
    if (!is_dir($LOGDIR)) { @mkdir($LOGDIR, 0755, true); }
    $ip = $_SERVER['REMOTE_ADDR'] ?? '';
    $salt = gmdate('Y-m-d'); // يتغير يوميًا => مفيش ربط بين الأيام
    $vid = substr(hash('sha256', $ip . '|' . $ua . '|' . $salt), 0, 16);
    $maskedIp = preg_replace('/\.\d+$/', '.0', $ip); // إخفاء آخر خانة
    $entry = [
        'ts'  => gmdate('c'),
        'vid' => $vid,
        'ip'  => $maskedIp,
        'ua'  => substr($ua, 0, 180),
        'ref' => substr($_SERVER['HTTP_REFERER'] ?? '', 0, 200),
    ];
    $line = json_encode($entry, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) . "\n";
    $fh = @fopen($LOG, 'a');
    if ($fh) { if (flock($fh, LOCK_EX)) { fwrite($fh, $line); flock($fh, LOCK_UN); } fclose($fh); }
}

header('Content-Type: application/octet-stream');
header('Content-Disposition: attachment; filename="' . $NAME . '"');
header('Content-Length: ' . filesize($FILE));
header('X-Content-Type-Options: nosniff');
header('X-Robots-Tag: noindex, nofollow');
header('Cache-Control: no-store');
header('Referrer-Policy: no-referrer');
if ($method === 'HEAD') { exit; }
readfile($FILE);
exit;
