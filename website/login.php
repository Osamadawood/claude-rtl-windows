<?php
require __DIR__ . '/auth.php';
if (is_logged_in()) { header('Location: stats.php'); exit; }
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if (!hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')) {
    $error = 'انتهت الجلسة، حاول مرة أخرى.';
  } else {
    $u = trim($_POST['username'] ?? ''); $p = $_POST['password'] ?? '';
    if ($u === STATS_USER && password_verify($p, STATS_PASS_HASH)) {
      session_regenerate_id(true); $_SESSION['auth'] = true;
      header('Location: stats.php'); exit;
    } else { usleep(600000); $error = 'بيانات الدخول غير صحيحة.'; }
  }
}
$csrf = csrf_token();
?>
<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="robots" content="noindex">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>تسجيل الدخول — Claude RTL</title>
<link rel="icon" href="assets/favicon/favicon.ico" sizes="48x48">
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@400;500;600;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/tokens.css">
<link rel="stylesheet" href="assets/stats.css">
</head>
<body class="stats-body stats-login">
  <form class="stats-login-card stats-login" method="post" autocomplete="on">
    <div class="stats-login-brand">
      <img src="assets/img/logo.svg" width="42" height="42" alt="">
      <div>
        <h1>لوحة Claude RTL</h1>
        <p>تسجيل الدخول للوحة التحميلات</p>
      </div>
    </div>
    <?php if ($error): ?><div class="stats-err"><?=htmlspecialchars($error)?></div><?php endif; ?>
    <label for="username">اسم المستخدم</label>
    <input id="username" name="username" autofocus autocomplete="username" value="<?=htmlspecialchars($_POST['username'] ?? '')?>">
    <label for="password">كلمة المرور</label>
    <input id="password" type="password" name="password" autocomplete="current-password">
    <input type="hidden" name="csrf" value="<?=htmlspecialchars($csrf)?>">
    <button type="submit" class="stats-btn stats-btn--primary">دخول</button>
    <a class="stats-login-back" href="/">← العودة للموقع</a>
  </form>
</body>
</html>
