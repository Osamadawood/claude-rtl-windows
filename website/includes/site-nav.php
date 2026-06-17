<?php

declare(strict_types=1);

/** @var string $navActive home|releases|privacy|terms */
$navActive = $navActive ?? '';

$navItems = [
    ['key' => 'home',     'href' => '/',           'label' => 'الرئيسية', 'section' => 'hero'],
    ['key' => 'features', 'href' => '/#features', 'label' => 'المميزات', 'section' => 'features'],
    ['key' => 'how',      'href' => '/#how',      'label' => 'كيف يعمل', 'section' => 'how'],
    ['key' => 'releases', 'href' => '/releases',   'label' => 'الإصدارات', 'section' => null],
];
?>
<nav>
    <div class="wrap nav-in">
        <a class="brand" href="/" aria-label="Claude RTL — الصفحة الرئيسية">
            <img src="/assets/img/logo.svg" width="26" height="26" alt="">
            <span>Claude RTL</span>
        </a>
        <div class="nav-menu" role="navigation" aria-label="التنقل الرئيسي">
            <?php foreach ($navItems as $item): ?>
                <?php
                $isActive = ($navActive === $item['key']);
                $cls = 'nav-link' . ($isActive ? ' is-active' : '');
                ?>
                <a class="<?= htmlspecialchars($cls, ENT_QUOTES, 'UTF-8') ?>"
                   href="<?= htmlspecialchars($item['href'], ENT_QUOTES, 'UTF-8') ?>"
                   <?php if (!empty($item['section'])): ?>data-nav="<?= htmlspecialchars($item['section'], ENT_QUOTES, 'UTF-8') ?>"<?php endif; ?>><?= $item['label'] ?></a>
            <?php endforeach; ?>
        </div>
        <a class="btn btn-primary btn-download" data-download href="/download/ClaudeRTL.dmg">نزّل لـ <span class="en">macOS</span></a>
    </div>
</nav>
