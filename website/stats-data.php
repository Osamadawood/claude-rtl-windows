<?php

date_default_timezone_set('Africa/Cairo');

function cairoDay(string $ts): string {
    $dt = new DateTime($ts);
    $dt->setTimezone(new DateTimeZone('Africa/Cairo'));
    return $dt->format('Y-m-d');
}

function fmtCairo(string $ts): string {
    $dt = new DateTime($ts);
    $dt->setTimezone(new DateTimeZone('Africa/Cairo'));
    return $dt->format('Y-m-d H:i');
}

function arDayName(string $dateStr): string {
    $names = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
    return $names[(int) date('w', strtotime($dateStr))] ?? '';
}

function parseOs(string $ua): string {
    if (preg_match('/Mac OS X ([0-9_]+)/', $ua, $m)) {
        return 'macOS ' . str_replace('_', '.', $m[1]);
    }
    if (stripos($ua, 'Macintosh') !== false) return 'macOS';
    if (stripos($ua, 'Windows') !== false) return 'Windows';
    if (stripos($ua, 'iPhone') !== false || stripos($ua, 'iPad') !== false) return 'iOS';
    if (stripos($ua, 'Android') !== false) return 'Android';
    if (stripos($ua, 'Linux') !== false) return 'Linux';
    return 'أخرى';
}

function isMacDl(string $ua): bool {
    $o = parseOs($ua);
    return strncmp($o, 'macOS', 5) === 0;
}

function parseBrowser(string $ua): string {
    if (stripos($ua, 'Edg') !== false) return 'Edge';
    if (stripos($ua, 'Chrome') !== false) return 'Chrome';
    if (stripos($ua, 'Safari') !== false) return 'Safari';
    if (stripos($ua, 'Firefox') !== false) return 'Firefox';
    return 'أخرى';
}

function refHost(string $ref): string {
    if ($ref === '') return 'مباشر';
    $h = parse_url($ref, PHP_URL_HOST);
    return $h ?: 'مباشر';
}

function hostContains(string $host, string $needle): bool {
    return strpos($host, $needle) !== false;
}

function trafficPlatform(string $ref, string $utmSource = '', string $utmMedium = ''): string {
    if ($utmSource !== '') {
        $label = $utmSource;
        if ($utmMedium !== '') {
            $label .= ' / ' . $utmMedium;
        }
        return 'UTM · ' . $label;
    }
    return trafficPlatformFromRef($ref);
}

function trafficPlatformFromRef(string $ref): string {
    if ($ref === '') {
        return 'مباشر / بدون مصدر';
    }
    $host = strtolower((string) parse_url($ref, PHP_URL_HOST));
    if ($host === '') {
        return 'مباشر / بدون مصدر';
    }
    if (hostContains($host, 'claude-rtl.grwlab.net')) {
        return 'داخلي · الموقع';
    }
    if (hostContains($host, 'grwlab.net')) {
        return 'GRW Lab';
    }

    $map = [
        ['google.', 'Google'],
        ['bing.com', 'Bing'],
        ['duckduckgo.com', 'DuckDuckGo'],
        ['yahoo.', 'Yahoo'],
        ['twitter.com', 'X / Twitter'],
        ['x.com', 'X / Twitter'],
        ['t.co', 'X / Twitter'],
        ['facebook.com', 'Facebook'],
        ['fb.com', 'Facebook'],
        ['l.facebook.com', 'Facebook'],
        ['instagram.com', 'Instagram'],
        ['linkedin.com', 'LinkedIn'],
        ['lnkd.in', 'LinkedIn'],
        ['reddit.com', 'Reddit'],
        ['youtube.com', 'YouTube'],
        ['youtu.be', 'YouTube'],
        ['tiktok.com', 'TikTok'],
        ['t.me', 'Telegram'],
        ['web.whatsapp.com', 'WhatsApp'],
        ['news.ycombinator.com', 'Hacker News'],
        ['producthunt.com', 'Product Hunt'],
        ['medium.com', 'Medium'],
        ['github.com', 'GitHub'],
        ['threads.net', 'Threads'],
        ['mastodon.', 'Mastodon'],
    ];

    foreach ($map as $item) {
        if (hostContains($host, $item[0])) {
            return $item[1];
        }
    }

    return $host;
}

function pageLabel(string $page): string {
    $path = parse_url($page, PHP_URL_PATH) ?: $page;
    if ($path === '/' || $path === '/index.html' || $path === '/index.php') return 'الرئيسية';
    if ($path === '/privacy' || $path === '/privacy.html') return 'الخصوصية';
    if ($path === '/terms' || $path === '/terms.html') return 'الشروط';
    if (strpos($path, '404') !== false) return '404';
    return $path;
}

function ago(string $ts): string {
    $s = time() - strtotime($ts);
    if ($s < 60) return 'الآن';
    if ($s < 3600) return floor($s / 60) . ' د';
    if ($s < 86400) return floor($s / 3600) . ' س';
    return floor($s / 86400) . ' ي';
}

function deltaLabel(int $today, int $yest): array {
    $diff = $today - $yest;
    if ($yest === 0) {
        if ($today === 0) return ['text' => 'بدون تغيّر', 'class' => 'flat'];
        return ['text' => '+' . $today . ' عن إمبارح', 'class' => 'up'];
    }
    $pct = (int) round(abs($diff) / $yest * 100);
    if ($diff > 0) return ['text' => '↑ ' . $diff . ' (' . $pct . '%)', 'class' => 'up'];
    if ($diff < 0) return ['text' => '↓ ' . abs($diff) . ' (' . $pct . '%)', 'class' => 'down'];
    return ['text' => '= إمبارح', 'class' => 'flat'];
}

function barsHtml(array $arr, int $top = 5): string {
    if (!$arr) return '<div class="muted">—</div>';
    $out = '';
    $i = 0;
    $mx = max(1, max($arr));
    foreach ($arr as $k => $v) {
        if ($i++ >= $top) break;
        $w = (int) round($v / $mx * 100);
        $out .= '<div class="rowbar"><span class="lbl">' . htmlspecialchars((string) $k) . '</span>'
            . '<span class="track"><b style="width:' . $w . '%"></b></span>'
            . '<span class="val">' . $v . '</span></div>';
    }
    return $out ?: '<div class="muted">—</div>';
}

function load_visits(): array {
    $log = __DIR__ . '/data/visits.ndjson';
    $rows = [];
    if (is_file($log)) {
        foreach (file($log, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $d = json_decode($line, true);
            if ($d) $rows[] = $d;
        }
    }

    $now = time();
    $todayStr = date('Y-m-d');
    $yestStr = date('Y-m-d', $now - 86400);

    $total = count($rows);
    $today = $yest = $week = $month = 0;
    $todayUniq = $yestUniq = [];
    $uniq = [];
    $platforms = [];
    $platformsToday = [];
    $platforms30 = [];
    $pages = [];
    $pagesToday = [];
    $rawHosts = [];

    foreach ($rows as $r) {
        $ts = strtotime($r['ts']);
        $day = cairoDay($r['ts']);
        $vid = $r['vid'] ?? (string) $ts;
        $platform = trafficPlatform($r['ref'] ?? '', $r['utm_source'] ?? '', $r['utm_medium'] ?? '');
        $page = pageLabel($r['page'] ?? '/');

        $uniq[$vid] = true;
        $platforms[$platform] = ($platforms[$platform] ?? 0) + 1;
        $pages[$page] = ($pages[$page] ?? 0) + 1;

        if ($day === $todayStr) {
            $today++;
            $todayUniq[$vid] = true;
            $platformsToday[$platform] = ($platformsToday[$platform] ?? 0) + 1;
            $pagesToday[$page] = ($pagesToday[$page] ?? 0) + 1;
        }
        if ($day === $yestStr) {
            $yest++;
            $yestUniq[$vid] = true;
        }
        if ($ts >= $now - 7 * 86400) {
            $week++;
        }
        if ($ts >= $now - 30 * 86400) {
            $month++;
            $platforms30[$platform] = ($platforms30[$platform] ?? 0) + 1;
        }

        $host = refHost($r['ref'] ?? '');
        if ($host !== 'مباشر') {
            $rawHosts[$host] = ($rawHosts[$host] ?? 0) + 1;
        }
    }

    arsort($platforms);
    arsort($platformsToday);
    arsort($platforms30);
    arsort($pages);
    arsort($pagesToday);
    arsort($rawHosts);

    $recent = array_slice(array_reverse($rows), 0, 40);
    $last = $recent[0] ?? null;

    return [
        'rows' => $rows,
        'total' => $total,
        'today' => $today,
        'yest' => $yest,
        'week' => $week,
        'month' => $month,
        'unique' => count($uniq),
        'today_uniq' => count($todayUniq),
        'yest_uniq' => count($yestUniq),
        'delta' => deltaLabel($today, $yest),
        'platforms' => $platforms,
        'platforms_today' => $platformsToday,
        'platforms_30' => $platforms30,
        'pages' => $pages,
        'pages_today' => $pagesToday,
        'raw_hosts' => $rawHosts,
        'recent' => $recent,
        'last' => $last,
    ];
}

function load_stats(): array {
    $log = __DIR__ . '/data/downloads.ndjson';
    $rows = [];
    if (is_file($log)) {
        foreach (file($log, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $d = json_decode($line, true);
            if ($d) $rows[] = $d;
        }
    }

    $now = time();
    $todayStr = date('Y-m-d');
    $yestStr = date('Y-m-d', $now - 86400);

    $total = count($rows);
    $today = $yest = $week = $month = 0;
    $todayUniq = $yestUniq = [];
    $uniq = [];
    $byDay = [];
    $refs = [];
    $os = [];
    $brw = [];
    $byHour = array_fill(0, 24, 0);
    $mac30 = 0;
    $other30 = 0;

    foreach ($rows as $r) {
        $ts = strtotime($r['ts']);
        $day = cairoDay($r['ts']);
        $vid = $r['vid'] ?? (string) $ts;

        $byDay[$day] = ($byDay[$day] ?? 0) + 1;
        $uniq[$vid] = true;

        if ($day === $todayStr) {
            $today++;
            $todayUniq[$vid] = true;
            $dt = new DateTime($r['ts']);
            $dt->setTimezone(new DateTimeZone('Africa/Cairo'));
            $byHour[(int) $dt->format('G')]++;
        }
        if ($day === $yestStr) {
            $yest++;
            $yestUniq[$vid] = true;
        }
        if ($ts >= $now - 7 * 86400) $week++;
        if ($ts >= $now - 30 * 86400) {
            $month++;
            if (isMacDl($r['ua'] ?? '')) $mac30++;
            else $other30++;
        }

        $h = trafficPlatformFromRef($r['ref'] ?? '');
        $refs[$h] = ($refs[$h] ?? 0) + 1;
        $o = parseOs($r['ua'] ?? '');
        $os[$o] = ($os[$o] ?? 0) + 1;
        $b = parseBrowser($r['ua'] ?? '');
        $brw[$b] = ($brw[$b] ?? 0) + 1;
    }

    arsort($refs);
    arsort($os);
    arsort($brw);

    $days14 = [];
    for ($i = 13; $i >= 0; $i--) {
        $d = date('Y-m-d', $now - $i * 86400);
        $days14[$d] = $byDay[$d] ?? 0;
    }

    $dailyTable = [];
    foreach ($days14 as $d => $c) {
        $dailyTable[] = [
            'date' => $d,
            'day' => arDayName($d),
            'count' => $c,
            'is_today' => $d === $todayStr,
        ];
    }

    $maxDay = max(1, max($days14 ?: [0]));
    $maxHour = max(1, max($byHour));
    $peakDay = array_keys($days14, max($days14 ?: [0]), true);
    $peakDay = $peakDay ? end($peakDay) : $todayStr;

    $recent = array_slice(array_reverse($rows), 0, 60);
    $last = $recent[0] ?? null;
    $macPct = ($mac30 + $other30) ? (int) round($mac30 / ($mac30 + $other30) * 100) : 0;
    $visits = load_visits();

    $stats = [
        'rows' => $rows,
        'visits' => $visits,
        'total' => $total,
        'today' => $today,
        'yest' => $yest,
        'week' => $week,
        'month' => $month,
        'unique' => count($uniq),
        'today_uniq' => count($todayUniq),
        'yest_uniq' => count($yestUniq),
        'avg7' => round($week / 7, 1),
        'avg30' => round($month / 30, 1),
        'mac30' => $mac30,
        'other30' => $other30,
        'mac_pct' => $macPct,
        'delta' => deltaLabel($today, $yest),
        'days14' => $days14,
        'daily_table' => array_reverse($dailyTable),
        'by_hour' => $byHour,
        'max_day' => $maxDay,
        'max_hour' => $maxHour,
        'peak_day' => $peakDay,
        'today_str' => $todayStr,
        'refs' => $refs,
        'os' => $os,
        'brw' => $brw,
        'recent' => $recent,
        'last' => $last,
        'demo_mode' => false,
    ];

    if (is_file(__DIR__ . '/stats-demo.php')) {
        require_once __DIR__ . '/stats-demo.php';
        $stats = apply_download_demo($stats);
    }

    return $stats;
}
