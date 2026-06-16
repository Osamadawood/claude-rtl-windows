(function() {
    "use strict";

    var DOWNLOAD_URL = "/download/ClaudeRTL.dmg";
    var APP_VERSION = "1.1.0";
    var reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    var yearEl = document.getElementById("year");
    if (yearEl) {
        yearEl.textContent = String(new Date().getFullYear());
    }

    var isMac =
        navigator.platform.indexOf("Mac") !== -1 ||
        /Mac/i.test(navigator.userAgent);

    document.documentElement.classList.add(isMac ? "is-macos" : "non-macos");

    document.querySelectorAll("[data-download]").forEach(function(btn) {
        btn.setAttribute("href", DOWNLOAD_URL);
        btn.removeAttribute("download");
    });

    var versionEl = document.getElementById("app-version");
    if (versionEl) {
        versionEl.textContent = APP_VERSION;
    }

    function initScrollUI() {
        var prog = document.getElementById("prog");
        if (prog) {
            window.addEventListener(
                "scroll",
                function() {
                    var h = document.documentElement;
                    var p = h.scrollTop / ((h.scrollHeight - h.clientHeight) || 1);
                    prog.style.transform = "scaleX(" + p + ")";
                }, {
                    passive: true
                }
            );
        }

        var nav = document.querySelector("nav");
        if (nav) {
            function updateNavScroll() {
                nav.classList.toggle("is-scrolled", window.scrollY > 24);
            }
            updateNavScroll();
            window.addEventListener("scroll", updateNavScroll, { passive: true });
        }

        var heroShot = document.querySelector(".hero .hero-shot");
        if (heroShot && !reducedMotion && window.matchMedia("(min-width: 901px)").matches) {
            window.addEventListener(
                "scroll",
                function() {
                    var hero = heroShot.closest(".hero");
                    if (!hero || !hero.classList.contains("is-live")) return;
                    var y = Math.min(window.scrollY * 0.045, 36);
                    heroShot.style.transform = "translateY(" + (-y) + "px)";
                }, {
                    passive: true
                }
            );
        }
    }

    var HERO_END_MS = 2100;
    var POST_HERO_ROW_DELAY_MS = 320;
    var heroDone = false;

    function reveal(el, delay) {
        if (delay) {
            el.style.transitionDelay = delay + "s";
        }
        el.classList.add("in");
    }

    function isPostHeroTarget(el) {
        return el.closest(".row-f--first");
    }

    function revealPostHeroContent() {
        var firstRow = document.querySelector(".row-f--first");
        if (!firstRow) return;

        firstRow.querySelectorAll("[data-a]").forEach(function(el, index) {
            reveal(el, index * 0.12);
        });
    }

    function onHeroComplete() {
        if (heroDone) return;
        heroDone = true;
        document.documentElement.classList.add("hero-done");

        setTimeout(revealPostHeroContent, POST_HERO_ROW_DELAY_MS);
    }

    function initHeroAnimation() {
        var hero = document.querySelector(".hero");
        if (!hero) {
            onHeroComplete();
            return;
        }

        if (reducedMotion) {
            hero.classList.add("is-live");
            onHeroComplete();
            return;
        }

        requestAnimationFrame(function() {
            requestAnimationFrame(function() {
                hero.classList.add("is-live");

                var bubble = hero.querySelector(".hero-bubble");
                if (bubble) {
                    bubble.addEventListener("animationend", onHeroComplete, {
                        once: true
                    });
                }

                setTimeout(onHeroComplete, HERO_END_MS);
            });
        });
    }

    function initAnimations() {
        var animTargets = document.querySelectorAll("[data-a], [data-shot]:not(.hero-shot)");

        if (reducedMotion) {
            animTargets.forEach(function(el) {
                el.classList.add("in");
            });
            document.querySelectorAll("[data-stagger]").forEach(function(el) {
                el.classList.add("in");
            });
            document.querySelectorAll(".page-error-in[data-a]").forEach(function(el) {
                el.classList.add("in");
            });
            initHeroAnimation();
            return;
        }

        document.documentElement.classList.add("js-ready");
        initHeroAnimation();

        if ("IntersectionObserver" in window) {
            var observer = new IntersectionObserver(
                function(entries) {
                    entries.forEach(function(entry) {
                        if (!entry.isIntersecting) return;
                        reveal(entry.target);
                        observer.unobserve(entry.target);
                    });
                }, {
                    root: null,
                    rootMargin: "0px 0px -10% 0px",
                    threshold: 0.08
                }
            );

            animTargets.forEach(function(el) {
                if (isPostHeroTarget(el)) return;
                observer.observe(el);
            });

            document.querySelectorAll("[data-stagger]").forEach(function(group) {
                observer.observe(group);
            });

            document.querySelectorAll(".page-error-in[data-a]").forEach(function(el) {
                reveal(el);
            });
        } else {
            animTargets.forEach(function(el) {
                if (isPostHeroTarget(el)) return;
                el.classList.add("in");
            });
            document.querySelectorAll("[data-stagger]").forEach(function(el) {
                el.classList.add("in");
            });
            document.querySelectorAll(".page-error-in[data-a]").forEach(function(el) {
                el.classList.add("in");
            });
        }
    }

    function initFaq() {
        var items = document.querySelectorAll(".faq-item");
        if (!items.length) return;

        items.forEach(function(item) {
            item.addEventListener("toggle", function() {
                if (!item.open) return;
                items.forEach(function(other) {
                    if (other !== item && other.open) {
                        other.open = false;
                    }
                });
            });
        });
    }

    function initHeroDemo() {
        var bubble = document.getElementById("heroDemoBubble");
        var textEl = document.getElementById("heroDemoText");
        var copyBtn = document.getElementById("heroCopy");
        var playBtn = document.getElementById("heroPlay");
        var toast = document.getElementById("heroToast");
        if (!bubble || !textEl || !copyBtn || !playBtn) return;

        var toastTimer;
        var copyTimer;
        var utterance = null;
        var plainText = "";

        function skipWrap(node) {
            return /^(CODE|SCRIPT|STYLE)$/i.test(node.tagName);
        }

        function wrapWords(root) {
            var index = 0;

            function walk(node) {
                if (node.nodeType === 3) {
                    var text = node.textContent;
                    if (!text) return;
                    var parts = text.split(/(\s+)/);
                    var frag = document.createDocumentFragment();
                    parts.forEach(function(part) {
                        if (!part) return;
                        if (/^\s+$/.test(part)) {
                            frag.appendChild(document.createTextNode(part));
                            index += part.length;
                        } else {
                            var span = document.createElement("span");
                            span.className = "w";
                            span.dataset.start = String(index);
                            span.textContent = part;
                            span.dataset.end = String(index + part.length);
                            index += part.length;
                            frag.appendChild(span);
                        }
                    });
                    node.parentNode.replaceChild(frag, node);
                    return;
                }
                if (node.nodeType === 1 && !skipWrap(node)) {
                    Array.prototype.slice.call(node.childNodes).forEach(walk);
                }
            }

            walk(root);
            plainText = root.innerText.replace(/\u00a0/g, " ");
        }

        function clearHighlight() {
            textEl.querySelectorAll(".w.on").forEach(function(el) {
                el.classList.remove("on");
            });
        }

        function highlightRange(start, length) {
            clearHighlight();
            if (length <= 0) return;
            var end = start + length;
            var first = null;
            textEl.querySelectorAll(".w").forEach(function(el) {
                var s = +el.dataset.start;
                var e = +el.dataset.end;
                if (s < end && e > start) {
                    el.classList.add("on");
                    if (!first) first = el;
                }
            });
            if (first) {
                first.scrollIntoView({
                    block: "nearest",
                    behavior: "smooth"
                });
            }
        }

        function showToast(message) {
            toast.textContent = message;
            toast.classList.add("is-visible");
            clearTimeout(toastTimer);
            toastTimer = setTimeout(function() {
                toast.classList.remove("is-visible");
            }, 1400);
        }

        function setCopied(active) {
            copyBtn.classList.toggle("is-copied", active);
            copyBtn.title = active ? "تم النسخ" : "نسخ";
            copyBtn.setAttribute("aria-label", active ? "تم النسخ" : "نسخ النص");
            clearTimeout(copyTimer);
            if (active) {
                copyTimer = setTimeout(function() {
                    setCopied(false);
                }, 1400);
            }
        }

        function onCopySuccess() {
            setCopied(true);
            showToast("✓ تم النسخ");
        }

        function setSpeaking(active) {
            playBtn.classList.toggle("is-speaking", active);
            playBtn.title = active ? "إيقاف" : "استماع للنص";
            playBtn.setAttribute("aria-label", active ? "إيقاف القراءة" : "استماع للنص");
            if (!active) clearHighlight();
        }

        function stopSpeech() {
            if (window.speechSynthesis) {
                window.speechSynthesis.cancel();
            }
            utterance = null;
            setSpeaking(false);
        }

        function pickArabicVoice() {
            if (!window.speechSynthesis) return null;
            var voices = window.speechSynthesis.getVoices();
            return (
                voices.find(function(v) {
                    return /^ar/i.test(v.lang);
                }) ||
                voices.find(function(v) {
                    return /arab/i.test(v.name);
                }) ||
                null
            );
        }

        function startSpeech() {
            if (!window.speechSynthesis || !plainText) {
                showToast("القراءة غير مدعومة هنا");
                return;
            }

            stopSpeech();
            utterance = new SpeechSynthesisUtterance(plainText);
            utterance.lang = "ar-SA";
            utterance.rate = 0.95;
            var voice = pickArabicVoice();
            if (voice) utterance.voice = voice;

            utterance.onstart = function() {
                setSpeaking(true);
            };

            utterance.onboundary = function(event) {
                if (event.name === "word" && event.charLength > 0) {
                    highlightRange(event.charIndex, event.charLength);
                }
            };

            utterance.onend = function() {
                setSpeaking(false);
            };

            utterance.onerror = function() {
                setSpeaking(false);
            };

            setSpeaking(true);
            window.speechSynthesis.speak(utterance);
        }

        function copyText() {
            var raw = plainText || textEl.innerText.replace(/\u00a0/g, " ").trim();
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(raw).then(onCopySuccess).catch(fallbackCopy);
            } else {
                fallbackCopy();
            }
        }

        function fallbackCopy() {
            var raw = plainText || textEl.innerText.replace(/\u00a0/g, " ").trim();
            var ta = document.createElement("textarea");
            ta.value = raw;
            ta.setAttribute("readonly", "");
            ta.style.position = "fixed";
            ta.style.opacity = "0";
            document.body.appendChild(ta);
            ta.select();
            try {
                document.execCommand("copy");
                onCopySuccess();
            } catch (e) {
                setCopied(false);
                showToast("تعذّر النسخ");
            }
            document.body.removeChild(ta);
        }

        wrapWords(textEl);

        copyBtn.addEventListener("click", copyText);
        playBtn.addEventListener("click", function() {
            if (playBtn.classList.contains("is-speaking")) {
                stopSpeech();
            } else {
                startSpeech();
            }
        });

        if (window.speechSynthesis) {
            window.speechSynthesis.onvoiceschanged = function() {};
        }
    }

    function finishPreloader(preloader) {
        document.body.classList.remove("is-loading");
        if (preloader) {
            preloader.classList.add("is-out");
            preloader.addEventListener(
                "transitionend",
                function() {
                    preloader.remove();
                }, {
                    once: true
                }
            );
            setTimeout(function() {
                if (preloader.parentNode) preloader.remove();
            }, 700);
        }
        initAnimations();
        initScrollUI();
        initHeroDemo();
        initFaq();
    }

    function runPreloader() {
        var preloader = document.getElementById("preloader");
        var started = Date.now();
        var minMs = reducedMotion ? 120 : 950;
        var done = false;

        function exit() {
            if (done) return;
            done = true;
            var wait = Math.max(0, minMs - (Date.now() - started));
            setTimeout(function() {
                finishPreloader(preloader);
            }, wait);
        }

        if (document.readyState === "complete") {
            exit();
        } else {
            window.addEventListener("load", exit, {
                once: true
            });
        }

        setTimeout(exit, 3200);
    }

    function initVisitTrack() {
        try {
            if (sessionStorage.getItem("crtl_v")) return;
            var path = window.location.pathname + window.location.search;
            if (/stats|login|logout|visit\.php/i.test(path)) return;

            sessionStorage.setItem("crtl_v", "1");

            var qs = new URLSearchParams(window.location.search);
            var body = new URLSearchParams();
            body.set("p", path);
            body.set("r", document.referrer || "");
            ["utm_source", "utm_medium", "utm_campaign"].forEach(function(key) {
                var val = qs.get(key);
                if (val) body.set(key, val);
            });

            if (navigator.sendBeacon) {
                navigator.sendBeacon("/visit.php", body);
            } else {
                fetch("/visit.php", {
                    method: "POST",
                    body: body,
                    keepalive: true,
                    credentials: "same-origin"
                });
            }
        } catch (e) {}
    }

    initVisitTrack();

    if (document.getElementById("preloader")) {
        runPreloader();
    } else {
        document.body.classList.remove("is-loading");
        initAnimations();
        initScrollUI();
        initHeroDemo();
        initFaq();
    }
})();