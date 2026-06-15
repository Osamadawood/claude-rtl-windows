<?php
require __DIR__ . '/auth.php';
require_login();
require __DIR__ . '/stats-data.php';

header('X-Robots-Tag: noindex, nofollow');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Pragma: no-cache');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');

$s = load_stats();
$v = $s['visits'];
$updated = date('Y-m-d H:i');
$demo = !empty($s['demo_mode']);
$lblRange = $demo ? 'منذ الإطلاق' : 'آخر 7 أيام';
$lblRange30 = $demo ? 'منذ الإطلاق' : 'آخر 30 يوم';
$lblPlatforms = $demo ? 'المنصات — منذ الإطلاق' : 'المنصات — 30 يوم';
?>
<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="robots" content="noindex">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Claude RTL — لوحة التحميلات</title>
<link rel="icon" href="assets/favicon/favicon.ico" sizes="48x48">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/tokens.css">
<link rel="stylesheet" href="assets/stats.css">
</head>
<body class="stats-body">

<?php if (!empty($s['demo_mode'])): ?>
<div class="stats-demo-banner">⚠ وضع العرض — أرقام تجريبية (إطلاق أمس). احذف <code>stats-demo.php</code> للعودة للحقيقي.</div>
<?php endif; ?>

<nav class="stats-nav">
  <div class="stats-nav-in">
    <a class="stats-brand" href="/">
      <img src="assets/img/logo.svg" width="26" height="26" alt="">
      <span>Claude RTL</span>
    </a>
    <div class="stats-nav-actions">
      <a class="stats-btn" href="stats-export.php">تصدير CSV</a>
      <button type="button" class="stats-btn" id="autoRefreshToggle" aria-pressed="true">تحديث تلقائي: مفعّل</button>
      <a class="stats-btn" href="">تحديث</a>
      <a class="stats-btn" href="logout.php">خروج</a>
    </div>
  </div>
</nav>

<main class="stats-wrap">
  <div class="stats-head">
    <div>
      <div class="stats-kicker"><span class="dot"></span> لوحة التحميلات</div>
      <h1>إحصائيات الموقع والتحميل</h1>
    </div>
    <div class="stats-meta">
      آخر تحديث: <?=htmlspecialchars($updated)?><br>
      توقيت القاهرة · <span id="autoRefreshNote">تحديث تلقائي كل 60 ث</span><br>
      <?=number_format($v['total'])?> زيارة · <?=number_format($s['total'])?> تحميل
    </div>
  </div>

  <section class="stats-section">
    <h2 class="stats-section-title">زيارات الموقع — من أين يأتي الزوار؟</h2>
    <p class="stats-panel-note">يُسجَّل أول زيارة في كل جلسة متصفح (مرة واحدة)، مع المصدر الخارجي أو UTM إن وُجد.</p>

    <?php if ($v['total'] === 0): ?>
    <div class="stats-panel stats-empty">
      <strong>لا توجد زيارات مسجّلة بعد</strong>
      <span>بعد رفع <code>visit.php</code> و<code>app.js</code>، أول زائر للموقع هيظهر هنا خلال دقائق.</span>
    </div>
    <?php else: ?>

    <?php if ($v['last']): ?>
    <div class="stats-insight">
      <div class="stats-insight-item">
        <strong>آخر زيارة <?=htmlspecialchars(ago($v['last']['ts']))?></strong>
        <span><?=htmlspecialchars(trafficPlatform($v['last']['ref'] ?? '', $v['last']['utm_source'] ?? '', $v['last']['utm_medium'] ?? ''))?> · <?=htmlspecialchars(pageLabel($v['last']['page'] ?? '/'))?></span>
      </div>
      <div class="stats-insight-item">
        <strong><?= (int) $v['today'] ?> زيارة النهارده</strong>
        <span class="sub <?=htmlspecialchars($v['delta']['class'])?>"><?=htmlspecialchars($v['delta']['text'])?> · <?= (int) $v['today_uniq'] ?> فريد</span>
      </div>
      <div class="stats-insight-item">
        <strong><?= (int) $v['month'] ?> زيارة<?= $demo ? ' (منذ الإطلاق)' : ' (30 يوم)' ?></strong>
        <span><?= (int) $v['unique'] ?> زائر فريد إجمالي</span>
      </div>
    </div>
    <?php endif; ?>

    <div class="stats-grid">
      <div class="stats-card"><div class="n"><?= (int) $v['total'] ?></div><div class="l">زيارات — الإجمالي</div></div>
      <div class="stats-card"><div class="n"><?= (int) $v['today'] ?></div><div class="l">النهارده</div></div>
      <div class="stats-card"><div class="n"><?= (int) $v['yest'] ?></div><div class="l">إمبارح</div></div>
      <div class="stats-card"><div class="n"><?= (int) $v['week'] ?></div><div class="l"><?=htmlspecialchars($lblRange)?></div></div>
      <div class="stats-card"><div class="n"><?= (int) $v['month'] ?></div><div class="l"><?=htmlspecialchars($lblRange30)?></div></div>
      <div class="stats-card"><div class="n"><?= (int) $v['unique'] ?></div><div class="l">زوار فريدون</div></div>
    </div>

    <div class="stats-cols">
      <div class="stats-panel">
        <h2><?=htmlspecialchars($lblPlatforms)?></h2>
        <?=barsHtml($v['platforms_30'], 8)?>
      </div>
      <div class="stats-panel">
        <h2>المنصات — النهارده</h2>
        <?=barsHtml($v['platforms_today'], 8)?>
      </div>
      <div class="stats-panel">
        <h2>صفحات الهبوط</h2>
        <?=barsHtml($v['pages'], 8)?>
      </div>
    </div>

    <?php if ($v['raw_hosts']): ?>
    <div class="stats-panel">
      <h2>نطاقات المصدر الخام (Referrer)</h2>
      <p class="stats-panel-note">للتفاصيل الدقيقة — قبل تصنيف المنصة</p>
      <?=barsHtml($v['raw_hosts'], 8)?>
    </div>
    <?php endif; ?>

    <div class="stats-panel">
      <h2>آخر 40 زيارة</h2>
      <div class="stats-table-wrap">
        <table class="stats-table">
          <tr><th>منذ</th><th>الوقت</th><th>المنصة</th><th>الصفحة</th><th>المتصفح</th><th>Referrer</th></tr>
          <?php foreach ($v['recent'] as $r): ?>
          <tr>
            <td class="pill"><?=htmlspecialchars(ago($r['ts']))?></td>
            <td class="pill"><?=htmlspecialchars(fmtCairo($r['ts']))?></td>
            <td><strong><?=htmlspecialchars(trafficPlatform($r['ref'] ?? '', $r['utm_source'] ?? '', $r['utm_medium'] ?? ''))?></strong></td>
            <td><?=htmlspecialchars(pageLabel($r['page'] ?? '/'))?></td>
            <td><?=htmlspecialchars(parseBrowser($r['ua'] ?? ''))?></td>
            <td class="muted"><?=htmlspecialchars(refHost($r['ref'] ?? ''))?></td>
          </tr>
          <?php endforeach; ?>
        </table>
      </div>
    </div>
    <?php endif; ?>
  </section>

  <section class="stats-section">
    <h2 class="stats-section-title">تحميلات التطبيق</h2>

  <?php if ($s['total'] === 0): ?>
  <div class="stats-panel stats-empty">
    <strong>لا توجد تحميلات بعد</strong>
    <span>أول ما حد ينزّل من /download/ClaudeRTL.dmg هتظهر البيانات هنا.</span>
  </div>
  <?php else: ?>

  <?php if ($s['last']): ?>
  <div class="stats-insight">
    <div class="stats-insight-item">
      <strong>آخر تحميل <?=htmlspecialchars(ago($s['last']['ts']))?></strong>
      <span><?=htmlspecialchars(parseBrowser($s['last']['ua'] ?? ''))?> · <?=htmlspecialchars(parseOs($s['last']['ua'] ?? ''))?> · <?=htmlspecialchars(trafficPlatformFromRef($s['last']['ref'] ?? ''))?></span>
    </div>
    <div class="stats-insight-item">
      <strong><?= $demo ? 'يوم الإطلاق' : 'أعلى يوم (14 يوم)' ?>: <?=htmlspecialchars($s['peak_day_label'] ?? $s['peak_day'])?></strong>
      <span><?= (int) ($s['days14'][$s['peak_day']] ?? 0) ?> تحميل</span>
    </div>
    <div class="stats-insight-item">
      <strong><?= (int) $s['mac_pct'] ?>% macOS<?= $demo ? ' (منذ الإطلاق)' : ' (30 يوم)' ?></strong>
      <span><span dir="ltr" class="num-ltr"><?= (int) $s['mac30'] ?> macOS · <?= (int) $s['other30'] ?> غير macOS</span></span>
    </div>
  </div>
  <?php endif; ?>

  <div class="stats-grid">
    <div class="stats-card">
      <div class="n"><?= (int) $s['total'] ?></div>
      <div class="l">الإجمالي</div>
    </div>
    <div class="stats-card">
      <div class="n"><?= (int) $s['today'] ?></div>
      <div class="l">النهارده</div>
      <div class="sub <?=htmlspecialchars($s['delta']['class'])?>"><?=htmlspecialchars($s['delta']['text'])?></div>
    </div>
    <div class="stats-card">
      <div class="n"><?= (int) $s['yest'] ?></div>
      <div class="l">إمبارح</div>
      <div class="sub flat"><?= (int) $s['yest_uniq'] ?> فريد</div>
    </div>
    <div class="stats-card">
      <div class="n"><?= (int) $s['week'] ?></div>
      <div class="l"><?=htmlspecialchars($lblRange)?></div>
    </div>
    <div class="stats-card">
      <div class="n"><?= (int) $s['month'] ?></div>
      <div class="l"><?=htmlspecialchars($lblRange30)?></div>
    </div>
    <div class="stats-card">
      <div class="n"><?= (int) $s['unique'] ?></div>
      <div class="l">تحميلات فريدة</div>
      <div class="sub flat"><?= (int) $s['today_uniq'] ?> النهارده</div>
    </div>
  </div>

  <div class="stats-grid stats-grid--3">
    <div class="stats-card">
      <div class="n"><?=htmlspecialchars((string) $s['avg7'])?></div>
      <div class="l"><?= $demo ? 'متوسط يومي (يومان)' : 'متوسط 7 أيام' ?></div>
    </div>
    <div class="stats-card">
      <div class="n"><?=htmlspecialchars((string) $s['avg30'])?></div>
      <div class="l"><?= $demo ? 'منذ الإطلاق' : 'متوسط 30 يوم' ?></div>
    </div>
    <div class="stats-card">
      <div class="n"><?=htmlspecialchars((string) ($s['hourly_rate'] ?? ($s['today'] > 0 ? round($s['today'] / max(1, (int) date('G') + 1), 1) : 0)))?></div>
      <div class="l">معدل/ساعة النهارده</div>
    </div>
  </div>

  <div class="stats-panel">
    <h2>التحميلات — آخر 14 يوم</h2>
    <?php if ($demo): ?><p class="stats-panel-note">التطبيق أُطلق أمس — يظهر يوم الإطلاق والنهارده فقط</p><?php endif; ?>
    <div class="stats-chart">
      <?php foreach ($s['days14'] as $d => $c): ?>
      <div class="bar<?=$d === $s['today_str'] ? ' bar--today' : ''?>" title="<?=htmlspecialchars($d)?>: <?=$c?>">
        <span style="height:<?= (int) round($c / $s['max_day'] * 100) ?>%"></span>
        <em><?=htmlspecialchars(substr($d, 8, 2))?></em>
      </div>
      <?php endforeach; ?>
    </div>
  </div>

  <?php if ($s['today'] > 0): ?>
  <div class="stats-panel">
    <h2>توزيع ساعات النهارده</h2>
    <p class="stats-panel-note">توقيت القاهرة — <?= (int) $s['today'] ?> تحميل</p>
    <div class="stats-chart stats-chart--hours">
      <?php for ($h = 0; $h < 24; $h++): $c = $s['by_hour'][$h]; ?>
      <div class="bar" title="<?=sprintf('%02d:00', $h)?>: <?=$c?>">
        <span style="height:<?= (int) round($c / $s['max_hour'] * 100) ?>%"></span>
        <em><?= $h % 3 === 0 ? sprintf('%02d', $h) : '' ?></em>
      </div>
      <?php endfor; ?>
    </div>
  </div>
  <?php endif; ?>

  <div class="stats-cols">
    <div class="stats-panel"><h2>مصادر التحميل</h2><?=barsHtml($s['refs'])?></div>
    <div class="stats-panel"><h2>نظام التشغيل</h2><?=barsHtml($s['os'])?></div>
    <div class="stats-panel"><h2>المتصفح</h2><?=barsHtml($s['brw'])?></div>
  </div>

  <div class="stats-panel">
    <h2>تفصيل يومي</h2>
    <div class="stats-table-wrap">
      <table class="stats-table">
        <tr><th>اليوم</th><th>التاريخ</th><th>تحميلات</th><th>فريد (تقريبي)</th></tr>
        <?php
        $dayUniq = [];
        foreach ($s['rows'] as $r) {
            $d = cairoDay($r['ts']);
            $dayUniq[$d][$r['vid'] ?? $r['ts']] = true;
        }
        foreach ($s['daily_table'] as $row):
        ?>
        <tr class="<?=$row['is_today'] ? 'row--today' : ''?>">
          <td><?=htmlspecialchars($row['day'])?><?=$row['is_today'] ? '<span class="tag">اليوم</span>' : ''?></td>
          <td class="pill"><?=htmlspecialchars($row['date'])?></td>
          <td><strong><?= (int) $row['count'] ?></strong></td>
          <td class="muted"><?= (int) ($row['uniq'] ?? count($dayUniq[$row['date']] ?? [])) ?></td>
        </tr>
        <?php endforeach; ?>
      </table>
    </div>
  </div>

  <div class="stats-panel">
    <h2>آخر 60 تحميل</h2>
    <div class="stats-table-wrap">
      <table class="stats-table">
        <tr><th>منذ</th><th>الوقت (القاهرة)</th><th>النظام</th><th>المتصفح</th><th>المنصة</th><th>IP</th></tr>
        <?php foreach ($s['recent'] as $r): ?>
        <tr>
          <td class="pill"><?=htmlspecialchars(ago($r['ts']))?></td>
          <td class="pill"><?=htmlspecialchars(fmtCairo($r['ts']))?></td>
          <td><?=htmlspecialchars(parseOs($r['ua'] ?? ''))?></td>
          <td><?=htmlspecialchars(parseBrowser($r['ua'] ?? ''))?></td>
          <td class="muted"><?=htmlspecialchars(trafficPlatformFromRef($r['ref'] ?? ''))?></td>
          <td class="pill"><?=htmlspecialchars($r['ip'] ?? '')?></td>
        </tr>
        <?php endforeach; ?>
      </table>
    </div>
  </div>

  <?php endif; ?>
  </section>
</main>
<script>
(function() {
  var KEY = "crtl_stats_autorefresh";
  var SEC = 60;
  var btn = document.getElementById("autoRefreshToggle");
  var note = document.getElementById("autoRefreshNote");
  var enabled = localStorage.getItem(KEY) !== "off";
  var timer = null;

  function apply() {
    if (timer) {
      clearInterval(timer);
      timer = null;
    }
    if (enabled) {
      timer = setInterval(function() { location.reload(); }, SEC * 1000);
      btn.textContent = "تحديث تلقائي: مفعّل";
      btn.setAttribute("aria-pressed", "true");
      btn.classList.add("is-on");
      if (note) note.textContent = "تحديث تلقائي كل " + SEC + " ث";
    } else {
      btn.textContent = "تحديث تلقائي: متوقف";
      btn.setAttribute("aria-pressed", "false");
      btn.classList.remove("is-on");
      if (note) note.textContent = "التحديث التلقائي متوقف";
    }
  }

  btn.addEventListener("click", function() {
    enabled = !enabled;
    localStorage.setItem(KEY, enabled ? "on" : "off");
    apply();
  });

  apply();
})();
</script>
</body>
</html>
