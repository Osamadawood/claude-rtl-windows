<?php
require __DIR__ . '/auth.php';
require_login();
require __DIR__ . '/stats-data.php';

$s = load_stats();

header('Content-Type: text/csv; charset=utf-8');
header('Content-Disposition: attachment; filename="claude-rtl-downloads-' . date('Y-m-d') . '.csv"');
header('Cache-Control: no-store');
header('X-Robots-Tag: noindex');

echo "\xEF\xBB\xBF";
$out = fopen('php://output', 'w');
fputcsv($out, ['الوقت (القاهرة)', 'منذ', 'النظام', 'المتصفح', 'المصدر', 'IP (مقنّع)', 'معرّف الزائر']);

foreach (array_reverse($s['rows']) as $r) {
    fputcsv($out, [
        fmtCairo($r['ts']),
        ago($r['ts']),
        parseOs($r['ua'] ?? ''),
        parseBrowser($r['ua'] ?? ''),
        refHost($r['ref'] ?? ''),
        $r['ip'] ?? '',
        $r['vid'] ?? '',
    ]);
}

fclose($out);
exit;
