<?php
// ===== Config =====
// 1) غيّر اسم المستخدم لو حابب.
// 2) ولّد هاش للباسورد بالأمر ده (على السيرفر أو محليًا) وحط الناتج في STATS_PASS_HASH:
//    php -r "echo password_hash('باسوردك_هنا', PASSWORD_DEFAULT), PHP_EOL;"
const STATS_USER = 'osama';
const STATS_PASS_HASH = '$2y$12$d2OiNbnCjOP9Jx3KPZJ7MuELjUcfO61x.k6R5xD79AyB69O64wnaS';

session_set_cookie_params([
  'lifetime' => 0, 'path' => '/', 'httponly' => true,
  'secure' => (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off'),
  'samesite' => 'Lax',
]);
session_name('crtl_admin');
session_start();

function is_logged_in(): bool { return !empty($_SESSION['auth']) && $_SESSION['auth'] === true; }
function require_login(): void { if (!is_logged_in()) { header('Location: login.php'); exit; } }
function csrf_token(): string {
  if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(16));
  return $_SESSION['csrf'];
}
