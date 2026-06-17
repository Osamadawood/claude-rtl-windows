<?php $navActive = 'home'; ?>
<!doctype html>
<html lang="ar" dir="rtl">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">

    <link rel="preconnect" href="https://www.googletagmanager.com">

    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-CSZJ1BQ66Q"></script>
    <script>
        window.dataLayer = window.dataLayer || [];

        function gtag() {
            dataLayer.push(arguments);
        }
        gtag('js', new Date());

        gtag('config', 'G-CSZJ1BQ66Q');
    </script>

    <title>Claude RTL — العربية كما يجب أن تُقرأ</title>
    <meta name="description" content="أداة مجانية لـ macOS تُصلِح اتجاه النص العربي عند نسخه (⌘C) في أي تطبيق — المتصفح، Claude، المحررات، وغيرها. Markdown، قراءة صوتية، إعدادات أصلية. كل شيء محلي.">
    <link rel="canonical" href="https://claude-rtl.grwlab.net/">
    <meta name="theme-color" content="#0c0a08">

    <meta property="og:type" content="website">
    <meta property="og:url" content="https://claude-rtl.grwlab.net/">
    <meta property="og:site_name" content="Claude RTL">
    <meta property="og:title" content="Claude RTL — العربية كما يجب أن تُقرأ">
    <meta property="og:description" content="أداة macOS مجانية تُصلِح اتجاه النص العربي في أي تطبيق — المتصفح، Claude، وأكثر — لحظة النسخ (⌘C).">
    <meta property="og:image" content="https://claude-rtl.grwlab.net/assets/screenshot.png">
    <meta property="og:image:width" content="1200">
    <meta property="og:image:height" content="630">
    <meta property="og:image:alt" content="Claude RTL — معاينة التطبيق على macOS">
    <meta property="og:locale" content="ar_AR">
    <?php require_once __DIR__ . '/site-meta.php'; echo fb_app_id_meta(); ?>

    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="Claude RTL — العربية كما يجب أن تُقرأ">
    <meta name="twitter:description" content="أداة macOS مجانية تُصلِح اتجاه النص العربي في أي تطبيق — المتصفح، Claude، وأكثر — لحظة النسخ (⌘C).">
    <meta name="twitter:image" content="https://claude-rtl.grwlab.net/assets/screenshot.png">

    <link rel="icon" href="assets/favicon/favicon.ico" sizes="48x48">
    <link rel="icon" type="image/png" sizes="32x32" href="assets/favicon/favicon-32x32.png">
    <link rel="icon" type="image/png" sizes="16x16" href="assets/favicon/favicon-16x16.png">
    <link rel="apple-touch-icon" sizes="180x180" href="assets/favicon/apple-icon-180x180.png">
    <link rel="manifest" href="assets/favicon/manifest.json">
    <meta name="msapplication-config" content="assets/favicon/browserconfig.xml">
    <meta name="msapplication-TileColor" content="#0c0a08">
    <meta name="msapplication-TileImage" content="assets/favicon/ms-icon-144x144.png">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Arabic:wght@300;400;500;600;700&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">

    <link rel="stylesheet" href="assets/tokens.css">
    <link rel="stylesheet" href="assets/styles.css">

    <script type="application/ld+json">
        {
            "@context": "https://schema.org",
            "@type": "SoftwareApplication",
            "name": "Claude RTL",
            "operatingSystem": "macOS 13.0+",
            "applicationCategory": "UtilitiesApplication",
            "description": "أداة مجانية لنظام macOS تُصلِح اتجاه النص العربي عند نسخه (⌘C) في أي تطبيق — المتصفح، Claude لسطح المكتب، المحررات، وغيرها. تنسيق Markdown، قراءة صوتية، إعدادات أصلية، وتحديثات تلقائية. تعمل محليًا بالكامل.",
            "softwareVersion": "1.1.0",
            "url": "https://claude-rtl.grwlab.net/",
            "downloadUrl": "https://claude-rtl.grwlab.net/download/ClaudeRTL.dmg",
            "inLanguage": "ar",
            "offers": {
                "@type": "Offer",
                "price": "0",
                "priceCurrency": "USD"
            },
            "publisher": {
                "@type": "Organization",
                "name": "GRW Lab",
                "url": "https://grwlab.net/"
            }
        }
    </script>
    <script type="application/ld+json">
        {
            "@context": "https://schema.org",
            "@type": "FAQPage",
            "mainEntity": [{
                    "@type": "Question",
                    "name": "هل Claude RTL مجاني؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "نعم، التطبيق مجاني بالكامل."
                    }
                },
                {
                    "@type": "Question",
                    "name": "على أي إصدار من macOS يعمل؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "يعمل على macOS 13 (Ventura) أو أحدث، وهو Universal يدعم معالجات Apple Silicon وIntel."
                    }
                },
                {
                    "@type": "Question",
                    "name": "أين يعمل Claude RTL؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "بشكل افتراضي في أي تطبيق على macOS: المتصفح (Safari وChrome وFirefox — بما فيها claude.ai)، تطبيق Claude لسطح المكتب، المحررات، وغيرها. انسخ نصًا عربيًا (⌘C) وستظهر الفقاعة. من الإعدادات يمكنك تقييد العمل على Claude فقط، أو قائمة تطبيقات محددة، أو استثناء تطبيقات معينة."
                    }
                },
                {
                    "@type": "Question",
                    "name": "هل يحتاج التطبيق إلى أذونات خاصة؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "لا. انسخ أي نص عربي بالضغط على ⌘C في التطبيق الذي تستخدمه، وستظهر الفقاعة بجوار المؤشّر. يمكنك تحديد التطبيقات المسموح بها من الإعدادات."
                    }
                },
                {
                    "@type": "Question",
                    "name": "كيف أحصل على التحديثات؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "من الإصدار 1.1.0 يُحدِّث التطبيق نفسه تلقائيًا عبر Sparkle. يمكنك أيضًا تنزيل أحدث نسخة من الموقع."
                    }
                },
                {
                    "@type": "Question",
                    "name": "هل تُرسَل أي من بياناتي إلى الإنترنت؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "لا. كل المعالجة تتم محليًا على جهازك، ولا يجمع التطبيق أي بيانات ولا يستخدم أي تتبّع."
                    }
                },
                {
                    "@type": "Question",
                    "name": "هل التطبيق تابع لشركة Anthropic؟",
                    "acceptedAnswer": {
                        "@type": "Answer",
                        "text": "لا، Claude RTL أداة مستقلة من GRW Lab، وغير تابعة لـ Anthropic ولا مُعتمَدة منها."
                    }
                }
            ]
        }
    </script>
</head>

<body class="is-loading">
    <div id="preloader" class="preloader" role="status" aria-live="polite" aria-label="جاري التحميل">
        <div class="preloader-inner">
            <img src="assets/img/logo.svg" width="48" height="48" alt="" class="preloader-logo">
            <div class="preloader-bar" aria-hidden="true"><span></span></div>
            <p class="preloader-label"><span class="en">Claude RTL</span></p>
        </div>
    </div>

    <div id="prog" aria-hidden="true"></div>

    <?php require __DIR__ . '/includes/site-nav.php'; ?>

    <header class="hero wrap">
        <div class="hero-bg" aria-hidden="true"></div>
        <div class="hero-grid">
            <div class="hero-copy">
                <div class="kicker"><span class="dot"></span> قارئ العربية لـ <span class="en">macOS</span></div>
                <h1>
                    <span class="hero-line">العربية في أي مكان،</span>
                    <span class="hero-line">كما يجب أن تُقرأ.</span>
                </h1>
                <p class="lead">أداةٌ مجانية لـ <span class="en">macOS</span> تُصلِح اتجاه النص العربي لحظة نسخه (<span class="en">⌘C</span>) — في المتصفح، <span class="en">Claude</span>، المحررات، أو أي تطبيق. عرضٌ صحيح، تنسيق <span class="en">Markdown</span>، وقراءةٌ صوتية. بلا أذونات خاصة، وبلا إرسال أي بيانات.</p>
                <div class="hero-cta">
                    <a class="btn btn-primary btn-download" data-download href="/download/ClaudeRTL.dmg">نزّل لـ <span class="en">macOS</span> <span class="tag">DMG</span></a>
                    <a class="btn btn-ghost" href="#how">كيف يعمل</a>
                </div>
                <div class="meta">مجاني · macOS 13+ · Universal · v<span id="app-version">1.1.0</span></div>
            </div>
            <div class="hero-shot" data-shot>
                <div class="shot">
                    <div class="bar"><i></i><i></i><i></i><span class="en">claude.ai</span></div>
                    <div class="body ba">
                        <div class="hero-panel hero-panel--before">
                            <div class="tagline"><span>في المتصفح</span><span class="x">قبل ✕</span></div>
                            <div class="broken">هذا النص العربي يُقرأ بالاتجاه الصحيح، مع <span class="code">code</span> وتنسيق.</div>
                        </div>
                        <div class="hero-panel hero-panel--after">
                            <div class="tagline"><span>مع Claude RTL</span><span class="v">بعد ✓</span></div>
                            <div class="bubble hero-bubble" id="heroDemoBubble">
                                <div class="bubble-head">
                                    <span class="d"></span> Claude RTL <span class="sp"></span>
                                    <button type="button" class="bubble-ic bubble-ic--copy" id="heroCopy" title="نسخ" aria-label="نسخ النص">
                                        <svg class="icon-copy" viewBox="0 0 24 24" aria-hidden="true">
                                            <rect x="9" y="9" width="11" height="11" rx="2" />
                                            <path d="M5 15V5a2 2 0 0 1 2-2h10" /></svg>
                                        <svg class="icon-check" viewBox="0 0 24 24" aria-hidden="true">
                                            <path d="M20 6 9 17l-5-5" /></svg>
                                    </button>
                                    <button type="button" class="bubble-ic bubble-ic--play" id="heroPlay" title="استماع للنص" aria-label="استماع للنص">
                                        <svg class="icon-play" viewBox="0 0 24 24" aria-hidden="true">
                                            <path d="M11 5 6 9H2v6h4l5 4z" />
                                            <path d="M15.5 8.5a5 5 0 0 1 0 7" /></svg>
                                        <svg class="icon-pause" viewBox="0 0 24 24" aria-hidden="true">
                                            <rect x="6" y="5" width="4" height="14" rx="1" />
                                            <rect x="14" y="5" width="4" height="14" rx="1" /></svg>
                                    </button>
                                </div>
                                <p id="heroDemoText">هذا النص العربي يُقرأ بالاتجاه الصحيح، مع <span class="code">code</span> وتنسيق <span class="en" style="color:var(--coral)">Markdown</span>.</p>
                                <div class="bubble-toast" id="heroToast" aria-live="polite"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </header>

    <div class="caps post-hero" aria-hidden="true">
        <div class="caps-track">
            <div class="row">
                <span>اتجاه RTL سليم</span><b>·</b><span>أي تطبيق</span><b>·</b><span>تنسيق Markdown</span><b>·</b><span>شيفرة LTR</span><b>·</b><span>قراءة صوتية</span><b>·</b><span>تمييز الكلمات</span><b>·</b><span>إعدادات أصلية</span><b>·</b><span>فاتح وداكن</span><b>·</b><span>تحديثات تلقائية</span><b>·</b><span>Universal</span><b>·</b>
                <span>اتجاه RTL سليم</span><b>·</b><span>أي تطبيق</span><b>·</b><span>تنسيق Markdown</span><b>·</b><span>شيفرة LTR</span><b>·</b><span>قراءة صوتية</span><b>·</b><span>تمييز الكلمات</span><b>·</b><span>إعدادات أصلية</span><b>·</b><span>فاتح وداكن</span><b>·</b><span>تحديثات تلقائية</span><b>·</b><span>Universal</span><b>·</b>
            </div>
        </div>
    </div>

    <section class="rows wrap" id="features">
        <div class="row-f row-f--first">
            <div class="copy" data-a>
                <div class="kicker"><span class="dot"></span> العرض</div>
                <h2>النص العربي، في اتجاهه الصحيح.</h2>
                <p class="lead">يعرض <span class="en">Claude RTL</span> النص بالاتجاه السليم مع تنسيق <span class="en">Markdown</span> كامل، ويُبقي الشيفرة البرمجية من اليسار إلى اليمين كما يجب.</p>
                <ul class="check">
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> اتجاه <span class="en">RTL</span> سليم للجُمل والفقرات</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> عناوين وقوائم وروابط <span class="en">Markdown</span></li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> الشيفرة تبقى <span class="en">LTR</span> داخل النص العربي</li>
                </ul>
            </div>
            <div data-a>
                <div class="shot">
                    <div class="bar"><i></i><i></i><i></i><span>Claude RTL</span></div>
                    <div class="body">
                        <div class="bubble">
                            <div class="bubble-head"><span class="d"></span> Claude RTL</div>
                            <p><b>عنوان فرعي</b><br>هذا النص العربي يُعرض بالاتجاه الصحيح، والكود <span class="code">npm install</span> يظل من اليسار لليمين.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row-f">
            <div class="copy" data-a>
                <div class="kicker"><span class="dot"></span> الاستماع</div>
                <h2>استمع، وتابع كل كلمة.</h2>
                <p class="lead">شغّل القراءة الصوتية، وكل كلمةٍ تُضاء أثناء نطقها — تجربة قراءة فريدة بالعربية تنفع المراجعة والاستيعاب.</p>
                <ul class="check">
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> قراءة صوتية واضحة بالعربية</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> تمييز الكلمة الحالية لحظة نطقها</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> تشغيل وإيقاف بنقرة واحدة</li>
                </ul>
            </div>
            <div data-a>
                <div class="shot">
                    <div class="bar"><i></i><i></i><i></i><span>Claude RTL</span></div>
                    <div class="body">
                        <div class="bubble">
                            <div class="bubble-head">
                                <span class="d"></span> Claude RTL <span class="sp"></span>
                                <svg viewBox="0 0 24 24" style="stroke:var(--coral)" aria-hidden="true">
                                    <path d="M11 5 6 9H2v6h4l5 4z" />
                                    <path d="M15.5 8.5a5 5 0 0 1 0 7" />
                                    <path d="M19 5a9 9 0 0 1 0 14" /></svg>
                            </div>
                            <p>تتحرّك القراءة كلمةً <mark>كلمة</mark> أثناء الاستماع، فتتابع النص بسهولة.</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="row-f">
            <div class="copy" data-a>
                <div class="kicker"><span class="dot"></span> الإعدادات</div>
                <h2>تحكّم كامل، بتصميم أصلي.</h2>
                <p class="lead">إعدادات <span class="en">SwiftUI</span> أصلية بالعربية: افتراضيًا يعمل في <strong>كل التطبيقات</strong> — أو قيّده على <span class="en">Claude</span> فقط، أو قائمة مخصّصة. المظهر، حجم الخط، والتشغيل التلقائي، مع تحديثات تلقائية.</p>
                <ul class="check">
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> افتراضيًا: أي تطبيق — متصفح، <span class="en">Claude</span>، محررات…</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> أو «<span class="en">Claude</span> فقط» / قائمة مخصّصة / استثناءات</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> مظهر تلقائي / فاتح / داكن وحجم خط الفقاعة</li>
                </ul>
            </div>
            <div data-a>
                <div class="shot">
                    <div class="bar"><i></i><i></i><i></i><span>الإعدادات</span></div>
                    <div class="body shot-center">
                        <svg class="shot-icon" viewBox="0 0 24 24" aria-hidden="true">
                            <circle cx="12" cy="12" r="3" />
                            <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" /></svg>
                        <p class="shot-title">إعدادات أصلية<br><span class="shot-sub">RTL · فاتح/داكن · تحديثات تلقائية</span></p>
                    </div>
                </div>
            </div>
        </div>

        <div class="row-f">
            <div class="copy" data-a>
                <div class="kicker"><span class="dot"></span> الخصوصية</div>
                <h2>محليًا تمامًا، بلا أذونات خاصة.</h2>
                <p class="lead">انسخ نصًا عربيًا (<span class="en">⌘C</span>) في أي تطبيق تختاره — الفقاعة تظهر بجوار المؤشّر. كل المعالجة على جهازك، دون إرسال أي بيانات.</p>
                <ul class="check">
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> لا يحتاج إذن <span class="en">Accessibility</span> أو أي صلاحية نظام</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> كل شيء محلي على جهازك</li>
                    <li><svg viewBox="0 0 24 24" aria-hidden="true">
                            <polyline points="20 6 9 17 4 12" /></svg> بلا تتبّع وبلا إرسال أي بيانات</li>
                </ul>
            </div>
            <div data-a>
                <div class="shot">
                    <div class="bar"><i></i><i></i><i></i><span>على جهازك</span></div>
                    <div class="body shot-center">
                        <svg class="shot-icon" viewBox="0 0 24 24" aria-hidden="true">
                            <path d="M12 2 4 5v6c0 5 3.4 8.5 8 11 4.6-2.5 8-6 8-11V5z" />
                            <polyline points="9 12 11 14 15 10" /></svg>
                        <p class="shot-title">لا تُرسَل أي بيانات.<br><span class="shot-sub">كل شيء يبقى على جهازك.</span></p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <section class="sec wrap" id="how">
        <div class="sec-head" data-a>
            <div class="kicker"><span class="dot"></span> كيف يعمل</div>
            <h2>ثلاث خطوات للبدء.</h2>
        </div>
        <div class="steps" data-stagger>
            <div class="step">
                <div class="n">الخطوة</div>
                <h3>نزّل ملف <span class="en">.dmg</span></h3>
                <p>حمّل <span class="en">Claude RTL</span> وافتح ملف التثبيت.</p>
            </div>
            <div class="step">
                <div class="n">الخطوة</div>
                <h3>اسحب إلى <span class="en">Applications</span></h3>
                <p>اسحب التطبيق إلى مجلد التطبيقات.</p>
            </div>
            <div class="step">
                <div class="n">الخطوة</div>
                <h3>انسخ نصًا عربيًا</h3>
                <p>حدّد النص في أي تطبيق واضغط <span class="en">⌘C</span> — ستظهر الفقاعة فورًا بجوار المؤشّر.</p>
            </div>
        </div>
    </section>

    <section class="sec wrap" id="faq">
        <div class="faq-grid">
            <div class="faq-copy" data-a>
                <div class="kicker"><span class="dot"></span> أسئلة شائعة</div>
                <h2>كل ما تريد معرفته.</h2>
                <p class="lead">إجابات مختصرة قبل أن تبدأ.</p>
                <div class="faq-contact">
                    <h3>التواصل</h3>
                    <p>لأي استفسار أو للإبلاغ عن مشكلة، تواصل معنا عبر <a href="https://grwlab.net/" target="_blank" rel="noopener noreferrer" class="en">grwlab.net</a> أو <a href="mailto:hello@grwlab.net" class="en">hello@grwlab.net</a>.</p>
                </div>
            </div>
            <div class="faq-list" data-stagger>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">هل Claude RTL مجاني؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>نعم، التطبيق مجاني بالكامل.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">على أي إصدار من macOS يعمل؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>يعمل على macOS 13 (Ventura) أو أحدث، وهو Universal يدعم معالجات Apple Silicon وIntel.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">أين يعمل Claude RTL؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>بشكل <strong>افتراضي في أي تطبيق</strong> على macOS: المتصفح (<span class="en">Safari</span>، <span class="en">Chrome</span>، <span class="en">Firefox</span> — بما فيها <span class="en">claude.ai</span>)، تطبيق <span class="en">Claude</span> لسطح المكتب، المحررات، وغيرها. انسخ نصًا عربيًا (<span class="en">⌘C</span>) وستظهر الفقاعة. من <strong>الإعدادات</strong> يمكنك تقييد العمل على <span class="en">Claude</span> فقط، أو قائمة تطبيقات محددة، أو استثناء تطبيقات معينة.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">هل يحتاج التطبيق إلى أذونات خاصة؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>لا. انسخ أي نص عربي بالضغط على <span class="en">⌘C</span> في التطبيق الذي تستخدمه، وستظهر الفقاعة. يمكنك تحديد التطبيقات المسموح بها أو المستثناة من <strong>الإعدادات</strong>.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">كيف أحصل على التحديثات؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>من الإصدار <span class="en">1.1.0</span> يُحدِّث التطبيق نفسه تلقائيًا. يمكنك أيضًا مراجعة <a href="/releases">سجل الإصدارات</a> وتنزيل أحدث نسخة من الموقع.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">هل تُرسَل أي من بياناتي إلى الإنترنت؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>لا. كل المعالجة تتم محليًا على جهازك، ولا يجمع التطبيق أي بيانات ولا يستخدم أي تتبّع.</p>
                        </div>
                    </div>
                </details>
                <details class="faq-item">
                    <summary>
                        <span class="faq-q">هل التطبيق تابع لشركة Anthropic؟</span>
                        <span class="faq-toggle" aria-hidden="true">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M12 5v14M5 12h14" /></svg>
                        </span>
                    </summary>
                    <div class="faq-body">
                        <div class="faq-body-inner">
                            <p>لا، Claude RTL أداة مستقلة من GRW Lab، وغير تابعة لـ Anthropic ولا مُعتمَدة منها.</p>
                        </div>
                    </div>
                </details>
            </div>
        </div>
    </section>

    <section class="cta wrap" id="download">
        <div class="kicker kicker--center" data-a><span class="dot"></span> ابدأ الآن</div>
        <h2 data-a>جرّبه الآن.</h2>
        <p class="lead" data-a>حمّل <span class="en">Claude RTL</span> مجانًا — واقرأ العربية بالاتجاه الصحيح في أي تطبيق.</p>
        <a class="btn btn-primary btn-download" data-a data-download href="/download/ClaudeRTL.dmg">نزّل لـ <span class="en">macOS</span> <span class="tag">DMG · UNIVERSAL</span></a>
        <div class="meta" data-a>macOS 13+ · Apple Silicon · Intel</div>
    </section>

    <?php require __DIR__ . '/includes/site-footer.php'; ?>

    <script src="assets/app.js" defer></script>
</body>

</html>
