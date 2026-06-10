(function () {
  "use strict";

  var DOWNLOAD_URL = "/download/ClaudeRTL-1.0.0.dmg";
  var APP_VERSION = "1.0.0";

  /* Footer year */
  var yearEl = document.getElementById("year");
  if (yearEl) {
    yearEl.textContent = String(new Date().getFullYear());
  }

  /* macOS detection */
  var isMac =
    navigator.platform.indexOf("Mac") !== -1 ||
    /Mac/i.test(navigator.userAgent);

  if (isMac) {
    document.documentElement.classList.add("is-macos");
  } else {
    document.documentElement.classList.add("non-macos");
  }

  /* Download buttons */
  document.querySelectorAll("[data-download]").forEach(function (btn) {
    btn.setAttribute("href", DOWNLOAD_URL);
    btn.setAttribute("download", "ClaudeRTL-" + APP_VERSION + ".dmg");
  });

  var versionEl = document.getElementById("app-version");
  if (versionEl) {
    versionEl.textContent = APP_VERSION;
  }

  /* Scroll reveal */
  if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    var reveals = document.querySelectorAll(".reveal");
    if (reveals.length && "IntersectionObserver" in window) {
      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting) {
              entry.target.classList.add("is-visible");
              observer.unobserve(entry.target);
            }
          });
        },
        { root: null, rootMargin: "0px 0px -8% 0px", threshold: 0.12 }
      );
      reveals.forEach(function (el) {
        observer.observe(el);
      });
    } else {
      reveals.forEach(function (el) {
        el.classList.add("is-visible");
      });
    }
  } else {
    document.querySelectorAll(".reveal").forEach(function (el) {
      el.classList.add("is-visible");
    });
  }

  /* Sticky nav shadow on scroll */
  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () {
      header.classList.toggle("is-scrolled", window.scrollY > 8);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }
})();
