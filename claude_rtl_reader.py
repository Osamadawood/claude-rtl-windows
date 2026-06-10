#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Claude RTL — Inline Bubble (restored + TTS)
- بيظهر بمجرد ما تعلّم على نص عربي في Claude (محتاج إذن Accessibility)،
  أو بالنسخ العادي ⌘C.
"""

import json
import re
import subprocess
import threading
import time

import webview  # pip install pywebview

AR = "\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF"
window = None
HIDDEN_POS = (-12000, -12000)
suppress_until = 0.0
_keep = []


def mouse_xy():
    try:
        from Quartz import CGEventCreate, CGEventGetLocation
        loc = CGEventGetLocation(CGEventCreate(None))
        return float(loc.x), float(loc.y)
    except Exception:
        return None


def frontmost_app():
    try:
        from AppKit import NSWorkspace
        app = NSWorkspace.sharedWorkspace().frontmostApplication()
        return app.localizedName() if app else ""
    except Exception:
        return ""


def get_clipboard():
    try:
        out = subprocess.run(["pbpaste"], capture_output=True, timeout=2)
        return out.stdout.decode("utf-8", "ignore")
    except Exception:
        return ""


def set_clipboard(text):
    try:
        subprocess.run(["pbcopy"], input=(text or "").encode("utf-8"))
    except Exception:
        pass


def has_arabic(text):
    return re.search("[" + AR + "]", text) is not None


def arabic_voice():
    try:
        out = subprocess.run(["say", "-v", "?"], capture_output=True, timeout=3)
        names = out.stdout.decode("utf-8", "ignore")
        for v in ("Maged", "Tarik", "Laila", "Majed"):
            if v in names:
                return v
    except Exception:
        pass
    return None


def show_bubble(text):
    xy = mouse_xy()
    if xy:
        try:
            window.move(int(xy[0]) - 20, int(xy[1]) + 14)
        except Exception:
            pass
    try:
        window.evaluate_js("window.showBubble(%s)" % json.dumps(text))
        window.show()
    except Exception:
        pass


class Api:
    def __init__(self):
        self.voice = None
        self.voice_checked = False

    def resize(self, w, h):
        try:
            window.resize(int(w), int(h))
        except Exception:
            pass
        return True

    def hide(self):
        try:
            window.move(*HIDDEN_POS)
            window.resize(2, 2)
            window.hide()
        except Exception:
            pass
        return True

    def copy(self, text):
        set_clipboard(text)
        return True

    def speak(self, text):
        try:
            subprocess.run(["pkill", "-x", "say"], capture_output=True)
        except Exception:
            pass
        try:
            if not self.voice_checked:
                self.voice = arabic_voice()
                self.voice_checked = True
            cmd = ["say"] + (["-v", self.voice] if self.voice else []) + [text or ""]
            subprocess.Popen(cmd)
        except Exception:
            pass
        return True


api = Api()

HTML = r"""
<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><style>
  :root{ --card:#1a1a20; --line:#34343f; --ink:#f2f2f5; --muted:#8f949c; --accent:#e8743b; }
  *{box-sizing:border-box}
  html,body{margin:0;height:100%;background:transparent;overflow:hidden;
    font-family:-apple-system,"SF Arabic","Geeza Pro",system-ui,sans-serif}
  .wrap{padding:14px}
  .bubble{position:relative;width:max-content;max-width:410px;
    background:linear-gradient(180deg,#24242c 0%,var(--card) 100%);
    border:1px solid var(--line);border-radius:18px;
    box-shadow:0 18px 50px rgba(0,0,0,.6),0 3px 10px rgba(0,0,0,.45);
    opacity:0;transform:translateY(-8px) scale(.96);
    transition:opacity .16s cubic-bezier(.2,.8,.2,1),transform .16s cubic-bezier(.2,.8,.2,1)}
  .bubble.show{opacity:1;transform:none}
  .arrow{position:absolute;top:-6px;inset-inline-start:34px;width:13px;height:13px;
    background:#24242c;border-inline-start:1px solid var(--line);
    border-block-start:1px solid var(--line);transform:rotate(45deg);border-radius:4px 0 0 0}
  .head{display:flex;align-items:center;gap:6px;padding:10px 14px 9px}
  .brand{font-size:11.5px;font-weight:800;letter-spacing:.4px;color:var(--accent);
    margin-inline-start:auto;display:flex;align-items:center;gap:6px;text-transform:uppercase}
  .brand .sp{width:5px;height:5px;border-radius:50%;background:var(--accent);box-shadow:0 0 8px var(--accent)}
  .ic{width:26px;height:26px;display:grid;place-items:center;border:none;
    background:transparent;color:var(--muted);border-radius:8px;cursor:pointer;transition:.13s}
  .ic:hover{background:#30303a;color:var(--ink)}
  .ic.play:hover{color:var(--accent)}
  .ic svg{width:15px;height:15px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}
  .body{position:relative;margin:0 14px;padding:11px 14px 12px;
    border-inline-start:3px solid var(--accent);background:#15151a;border-radius:10px;
    max-height:290px;overflow-y:auto;font-size:16px;line-height:1.85;color:var(--ink);unicode-bidi:plaintext}
  .body::-webkit-scrollbar{width:8px}
  .body::-webkit-scrollbar-thumb{background:#3a3a44;border-radius:8px}
  .body p,.body li,.body blockquote,.body h1,.body h2,.body h3,.body h4{unicode-bidi:plaintext;margin:.12em 0 .5em}
  .body>:first-child{margin-top:0}.body>:last-child{margin-bottom:0}
  .body h1{font-size:1.32em}.body h2{font-size:1.18em}.body h3{font-size:1.07em}
  .body ul,.body ol{margin:.25em 0 .55em;padding-inline-start:1.3em}
  .body li{margin:.12em 0}
  .body blockquote{border-inline-start:3px solid var(--accent);padding-inline-start:11px;color:var(--muted)}
  .body a{color:#7fb0ff;text-decoration:none}
  .body hr{border:none;border-top:1px solid var(--line);margin:.7em 0}
  .body strong{font-weight:700}.body em{font-style:italic}
  .body code.inl{background:#0d0d11;border:1px solid var(--line);border-radius:6px;
    padding:1px 6px;font-family:"SF Mono",Menlo,monospace;font-size:.85em;direction:ltr;unicode-bidi:isolate}
  .body pre{direction:ltr;unicode-bidi:isolate;text-align:left;background:#0a0a0d;
    border:1px solid var(--line);border-radius:10px;padding:10px 12px;overflow-x:auto;margin:.3em 0 .55em}
  .body pre code{font-family:"SF Mono",Menlo,monospace;font-size:13px;line-height:1.55;white-space:pre;color:#d6d6da}
  .foot{padding:8px 0 9px;text-align:center;font-size:10px;letter-spacing:.3px;color:#5b6068}
  .foot b{color:var(--accent);font-weight:700}
  .toast{position:absolute;bottom:34px;inset-inline:0;margin:auto;width:max-content;
    background:#000c;color:#fff;font-size:11.5px;padding:5px 12px;border-radius:8px;opacity:0;transition:.2s;pointer-events:none}
  .toast.show{opacity:1}
</style></head><body>
  <div class="wrap"><div class="bubble" id="bubble">
    <div class="arrow"></div>
    <div class="head">
      <button class="ic" id="bClose" title="اغلاق (Esc)"><svg viewBox="0 0 24 24"><line x1="6" y1="6" x2="18" y2="18"/><line x1="18" y1="6" x2="6" y2="18"/></svg></button>
      <button class="ic play" id="bPlay" title="استماع للنص"><svg viewBox="0 0 24 24"><path d="M11 5 6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7"/><path d="M18.5 5.5a9 9 0 0 1 0 13"/></svg></button>
      <button class="ic" id="bCopy" title="نسخ"><svg viewBox="0 0 24 24"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg></button>
      <span class="brand"><span class="sp"></span>Claude RTL</span>
    </div>
    <div class="body" id="body"></div>
    <div class="foot" dir="ltr">by <b>GRW&nbsp;Lab</b> &mdash; grwlab.net</div>
    <div class="toast" id="toast">اتنسخ ✓</div>
  </div></div>

<script>
  var RAW = "", autoT, toastT;
  function esc(s){return s.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");}
  function mdToHtml(src){
    src = src.replace(/\r\n/g,"\n");
    var codes = [];
    src = src.replace(/```([\w+-]*)\n?([\s\S]*?)```/g, function(m, lang, code){
      codes.push(code.replace(/\n$/,"")); return "@@C"+(codes.length-1)+"@@";
    });
    src = esc(src);
    src = src.replace(/`([^`]+)`/g, function(m,c){return '<code class="inl">'+c+"</code>";});
    src = src.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    src = src.replace(/(^|[^*])\*([^*\n]+)\*/g, "$1<em>$2</em>");
    src = src.replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, '<a href="$2">$1</a>');
    var lines = src.split("\n"), out = [], i = 0, list = null;
    function close(){ if(list){ out.push("</"+list+">"); list=null; } }
    while(i < lines.length){
      var ln = lines[i];
      var cm = ln.match(/^@@C(\d+)@@$/);
      if(cm){ close(); out.push("<pre><code>"+esc(codes[+cm[1]])+"</code></pre>"); i++; continue; }
      var h = ln.match(/^(#{1,6})\s+(.*)$/);
      if(h){ close(); var l=h[1].length; out.push("<h"+l+">"+h[2]+"</h"+l+">"); i++; continue; }
      if(/^\s*([-*+_]){3,}\s*$/.test(ln)){ close(); out.push("<hr>"); i++; continue; }
      if(/^\s*>\s?/.test(ln)){ close(); out.push("<blockquote>"+ln.replace(/^\s*>\s?/,"")+"</blockquote>"); i++; continue; }
      var ul = ln.match(/^\s*[-*+]\s+(.*)$/);
      if(ul){ if(list!=="ul"){close(); out.push("<ul>"); list="ul";} out.push("<li>"+ul[1]+"</li>"); i++; continue; }
      var ol = ln.match(/^\s*\d+[.)]\s+(.*)$/);
      if(ol){ if(list!=="ol"){close(); out.push("<ol>"); list="ol";} out.push("<li>"+ol[1]+"</li>"); i++; continue; }
      if(ln.trim()===""){ close(); i++; continue; }
      close();
      var buf=[ln]; i++;
      while(i<lines.length && lines[i].trim()!=="" && !/^@@C\d+@@$/.test(lines[i])
            && !/^(#{1,6})\s/.test(lines[i]) && !/^\s*[-*+]\s/.test(lines[i])
            && !/^\s*\d+[.)]\s/.test(lines[i]) && !/^\s*>\s?/.test(lines[i])){
        buf.push(lines[i]); i++;
      }
      out.push('<p dir="auto">'+buf.join("<br>")+"</p>");
    }
    close(); return out.join("");
  }
  function fit(){
    var b=document.getElementById("bubble"); var r=b.getBoundingClientRect();
    if(window.pywebview) window.pywebview.api.resize(Math.ceil(r.width)+28, Math.ceil(r.height)+28);
  }
  function showBubble(text){
    RAW = text;
    document.getElementById("body").innerHTML = mdToHtml(text);
    document.getElementById("body").scrollTop = 0;
    document.getElementById("bubble").classList.add("show");
    requestAnimationFrame(function(){ requestAnimationFrame(fit); });
    clearTimeout(autoT); autoT=setTimeout(hide, 12000);
  }
  function hide(){
    document.getElementById("bubble").classList.remove("show");
    if(window.pywebview) setTimeout(function(){ window.pywebview.api.hide(); }, 160);
  }
  document.getElementById("bClose").onclick=hide;
  document.getElementById("bPlay").onclick=function(){ if(window.pywebview) window.pywebview.api.speak(RAW); };
  document.getElementById("bCopy").onclick=function(){
    if(window.pywebview) window.pywebview.api.copy(RAW);
    var t=document.getElementById("toast"); t.classList.add("show");
    clearTimeout(toastT); toastT=setTimeout(function(){ t.classList.remove("show"); }, 1400);
  };
  document.addEventListener("keydown", function(e){ if(e.key==="Escape") hide(); });
  var bub=document.getElementById("bubble");
  bub.addEventListener("mouseenter", function(){ clearTimeout(autoT); });
  bub.addEventListener("mouseleave", function(){ clearTimeout(autoT); autoT=setTimeout(hide, 3500); });
  window.showBubble = showBubble;
</script></body></html>
"""


def clipboard_watcher():
    last = get_clipboard()
    while True:
        time.sleep(0.4)
        try:
            cur = get_clipboard()
            if cur == last:
                continue
            last = cur
            if time.time() < suppress_until:
                continue
            if cur and has_arabic(cur) and frontmost_app() == "Claude":
                show_bubble(cur)
        except Exception:
            pass


def press_cmd_c():
    try:
        from Quartz import (CGEventCreateKeyboardEvent, CGEventSetFlags,
                            CGEventPost, kCGHIDEventTap, kCGEventFlagMaskCommand)
        d = CGEventCreateKeyboardEvent(None, 8, True)
        CGEventSetFlags(d, kCGEventFlagMaskCommand)
        u = CGEventCreateKeyboardEvent(None, 8, False)
        CGEventSetFlags(u, kCGEventFlagMaskCommand)
        CGEventPost(kCGHIDEventTap, d)
        CGEventPost(kCGHIDEventTap, u)
    except Exception:
        pass


def capture_selection():
    global suppress_until
    suppress_until = time.time() + 1.3
    old = get_clipboard()
    press_cmd_c()
    new = ""
    for _ in range(8):
        time.sleep(0.05)
        cur = get_clipboard()
        if cur and cur != old:
            new = cur
            break
    set_clipboard(old)
    if new and has_arabic(new):
        show_bubble(new)


def selection_tap_thread():
    try:
        from Quartz import (
            CGEventTapCreate, kCGSessionEventTap, kCGHeadInsertEventTap,
            kCGEventTapOptionListenOnly, CGEventMaskBit,
            kCGEventLeftMouseDown, kCGEventLeftMouseUp,
            CFMachPortCreateRunLoopSource, CFRunLoopAddSource,
            CFRunLoopGetCurrent, kCFRunLoopCommonModes,
            CGEventTapEnable, CFRunLoopRun, CGEventGetLocation,
        )
    except Exception:
        return
    down = {"x": 0.0, "y": 0.0}

    def cb(proxy, etype, event, refcon):
        try:
            loc = CGEventGetLocation(event)
            if etype == kCGEventLeftMouseDown:
                down["x"], down["y"] = loc.x, loc.y
            elif etype == kCGEventLeftMouseUp:
                dx = loc.x - down["x"]; dy = loc.y - down["y"]
                if (dx * dx + dy * dy) > 36 and frontmost_app() == "Claude":
                    threading.Thread(target=capture_selection, daemon=True).start()
        except Exception:
            pass
        return event

    mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp)
    tap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                           kCGEventTapOptionListenOnly, mask, cb, None)
    if not tap:
        return
    src = CFMachPortCreateRunLoopSource(None, tap, 0)
    _keep.extend([tap, src, cb])
    CFRunLoopAddSource(CFRunLoopGetCurrent(), src, kCFRunLoopCommonModes)
    CGEventTapEnable(tap, True)
    CFRunLoopRun()


def main():
    global window
    window = webview.create_window(
        "Claude RTL", html=HTML,
        width=440, height=420,
        frameless=True, easy_drag=True, on_top=True,
        transparent=True, background_color="#000000",
        hidden=True,
    )
    threading.Thread(target=clipboard_watcher, daemon=True).start()
    threading.Thread(target=selection_tap_thread, daemon=True).start()
    webview.start()


if __name__ == "__main__":
    main()
