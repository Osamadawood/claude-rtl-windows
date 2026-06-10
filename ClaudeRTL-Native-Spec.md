# Claude RTL — Native macOS App (Cursor Build Spec)

> هدف السبيك ده: نبني تطبيق ماك أصلي (native) اسمه **Claude RTL** يحل
> مشاكل البروتوتايب نهائيًا: بالون بيظهر عند المؤشّر فوق Claude، **مبيعلّقش**
> المكان، **مبياخدش الفوكس**، زراره (نسخ/نُطق/إغلاق) شغّالة، وبيقفل بالكليك بره
> أو بـ ×. نفس التصميم اللي اتفقنا عليه (Dark + برتقالي GRW).

---

## 0. ليه native؟ (المشكلة اللي بنحلها)
البروتوتايب اتعمل بـ pywebview، ونوع نافذته العادية:
- بتاخد الفوكس لما تظهر → أول كليك بيفعّلها بدل ما يدوس الزرار → الزراير "مش شغّالة".
- بتمسك الكليكات في منطقتها حتى وهي مش محتاجة → "بتعلّق" الـ UI تحتها.

الحل: **`NSPanel` بنمط `.nonactivatingPanel`** + `becomesKeyOnlyIfNeeded` +
`acceptsFirstMouse` → النافذة تستقبل الكليك على الزرار من غير ما تسرق الفوكس،
وبتقفل بمجرد كليك بره. ده بالظبط اللي pywebview مش بيوصله.

---

## 1. Stack & setup
- **اللغة:** Swift 5.9+ / AppKit (مش SwiftUI للنافذة نفسها — محتاجين تحكم `NSPanel`).
- **الواجهة الداخلية للبالون:** `WKWebView` بيرندر نفس الـ HTML/CSS/JS بتاعنا
  (إعادة استخدام كاملة لمحرّك الـ Markdown/RTL — موجود في القسم 5).
- **النوع:** Menu-bar app (`LSUIElement = YES`, مفيش أيقونة Dock).
- **أقل نسخة:** macOS 12+.
- **Xcode project:** App target اسمه `ClaudeRTL`، Bundle ID `net.grwlab.claudertl`.

خطوات الإنشاء:
1. `App` بدون Storyboard. نقطة الدخول `@main struct ... : NSApplicationDelegate` أو `main.swift` + `NSApplication`.
2. أضف `WebKit`, `AppKit`, `ApplicationServices`, `Carbon` (لو هنستخدم HotKey لاحقًا).
3. Capabilities: عطّل App Sandbox **مؤقتًا** أثناء التطوير (الـ event tap بيحتاج خروج من الساندبوكس؛ للنشر بنستخدم Accessibility entitlement بدل الساندبوكس الكامل، انظر القسم 11).

---

## 2. المعمارية (ملفات مقترحة)
```
ClaudeRTL/
├── AppDelegate.swift          // menu-bar item, lifecycle, permissions
├── BubblePanel.swift          // NSPanel non-activating + WKWebView host
├── BubbleRenderer.swift       // الـ HTML string + جسر JS↔Swift
├── SelectionMonitor.swift     // CGEventTap: mouse-up → grab selection
├── Clipboard.swift            // read/write/save+restore
├── Speech.swift               // AVSpeechSynthesizer (صوت عربي)
├── Settings.swift             // UserDefaults: enabled, fontSize, autostart
├── Resources/bubble.html      // محرّك الرندر (القسم 5)
└── Info.plist                 // LSUIElement = YES
```

---

## 3. BubblePanel.swift — أهم ملف (يحل التعليق والفوكس)
المتطلبات:
- نوع النافذة: `NSPanel`.
- StyleMask: `[.nonactivatingPanel, .borderless]`.
- `level = .statusBar` (فوق نوافذ التطبيقات).
- `isFloatingPanel = true`, `hidesOnDeactivate = false`.
- `backgroundColor = .clear`, `isOpaque = false`, `hasShadow = false`
  (الظل بيتعمل في الـ HTML/CSS عشان الزوايا الدائرية).
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`.
- الـ panel **مبيبقاش key** إلا لما يحتاج: نعمل subclass override:

```swift
final class BubblePanel: NSPanel {
    override var canBecomeKey: Bool { true }      // عشان الزراير و Esc تشتغل
    override var canBecomeMain: Bool { false }     // بس من غير ما يبقى main/يسرق التطبيق
}
```

- نستضيف `WKWebView` كـ contentView، ونخلّي الـ webview `acceptsFirstMouse`
  يرجّع true (subclass) عشان أول كليك على الزرار يشتغل فورًا:

```swift
final class ClickableWebView: WKWebView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
```

السلوك:
- `show(at point: NSPoint, html content via JS)`: نحدّد حجم الـ panel من المحتوى
  (الـ JS بيبلّغ بالأبعاد عبر message handler — القسم 5)، نحط الـ origin عند المؤشّر
  مع offset بسيط (تحت/جنب)، `orderFrontRegardless()` (مش `makeKeyAndOrderFront`
  عشان ما يسرقش الفوكس)، وبعدين `makeKey()` فقط لو محتاجين الكتابة (مش محتاجين هنا).
- **إغلاق بكليك بره:** نركّب global monitor:
```swift
NSEvent.addGlobalMonitorForEventsMatchingMask(.leftMouseDown) { _ in self.hide() }
```
  (الكليك بره بيروح لـ Claude عادي ويقفل البالون — ده اللي طلبته بالظبط.)
- **إغلاق بـ Esc:** local monitor لـ `.keyDown` لو panel هو key.
- **إخفاء:** `orderOut(nil)` — النافذة بتختفي تمامًا، مفيش لاير فاضل (المشكلة اللي عندك تتحل هنا لأن الـ panel الحقيقي بيختفي فعلًا).
- **Auto-hide:** Timer 12s، بيتلغي لو الماوس فوق البالون.

---

## 4. SelectionMonitor.swift — الظهور بمجرد التحديد
- `CGEvent.tapCreate` يستمع لـ `.leftMouseDown` و `.leftMouseUp` (listenOnly).
- on down: خزّن النقطة. on up: لو المسافة > ~6px **و** التطبيق الأمامي = "Claude":
  - احفظ الحافظة الحالية، اعمل synth ⌘C (`CGEvent` keyDown/up بفلاج command)،
    استنى ~120ms، اقرا الحافظة الجديدة، **رجّع** الحافظة القديمة.
  - لو فيه نص عربي → `BubblePanel.show(at: mouseLocation)`.
- تشغيل الـ tap على RunLoop بتاع خيط مخصّص:
```swift
let src = CFMachPortCreateRunLoopSource(nil, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)
CFRunLoopRun()
```
- **fallback:** خلّي مراقبة الحافظة (⌘C اليدوي) شغّالة برضه لو الإذن مش متاح.
- كشف عربي: regex على نطاقات يونيكود `\u0600-\u06FF` ... (نفس البروتوتايب).

### إذن Accessibility
- استخدم `AXIsProcessTrustedWithOptions` مع
  `kAXTrustedCheckOptionPrompt = true` عند أول تشغيل → بيطلع البوب-أب الرسمي
  ويضيف التطبيق في القايمة. (ميزة الـ native: الإذن بيتربط بالتطبيق الموقّع
  مش بـ "Python"، فمفيش اللخبطة اللي حصلت في البروتوتايب.)

---

## 5. Resources/bubble.html — محرّك الرندر (إعادة استخدام تصميمنا)
استخدم نفس الـ HTML/CSS/JS بتاع البروتوتايب (RTL + Markdown + الكود LTR + تصميم
GRW البرتقالي). تعديلين بس:
1. بدل `window.pywebview.api.*` استخدم جسر WebKit:
   - Swift: `userContentController.add(self, name: "bridge")`
   - JS: `window.webkit.messageHandlers.bridge.postMessage({action:"copy", text})`
     للأكشنز (copy/speak/close/resize).
2. التحجيم: بعد الرندر، الـ JS يقيس `bubble.getBoundingClientRect()` ويبعت
   `{action:"resize", w, h}` → Swift يضبط حجم الـ panel.

الأكشنز من Swift:
- `copy` → `NSPasteboard.general` set string.
- `speak` → `Speech.shared.speak(text)`.
- `close` → `panel.hide()`.
- `resize` → `panel.setContentSize(NSSize(w,h))` مع إعادة ضبط الـ origin.

> ملف الـ HTML الكامل موجود عندك في البروتوتايب (`claude_rtl_reader.py` →
> ثابت `HTML`). انسخه كـ `bubble.html` وبدّل نداءات الـ API زي ما فوق.

---

## 6. Speech.swift — النُطق (شغّال صح)
- استخدم `AVSpeechSynthesizer` + `AVSpeechSynthesisVoice(language: "ar-SA")`
  (أنضف من `say` وبيشتغل من غير أصوات إضافية لو متوفّر صوت عربي بالنظام).
- لو مفيش صوت عربي: fallback لـ `Process` بـ `/usr/bin/say -v Maged`.
- زرار النطق بيوقف النطق الحالي قبل ما يبدأ جديد.

---

## 7. Settings + Menu bar
- `NSStatusItem` بأيقونة (template SVG/PDF برتقالي GRW).
- قايمة: تفعيل/تعطيل، حجم الخط (−/+)، "تشغيل عند بدء النظام"
  (`SMAppService.mainApp.register()` بدل launchd)، "حول"، خروج.
- `UserDefaults` للحفظ.

---

## 8. Branding
- Accent: `#e8743b`. خلفية: تدرّج `#24242c → #1a1a20`. حدود `#34343f`.
- خط: نظام (`-apple-system`, "SF Arabic"). فوتر: `by GRW Lab — grwlab.net` (dir=ltr).
- أيقونة التطبيق: شعار GRW (هجهّزها لاحقًا).

---

## 9. خطوات التشغيل والاختبار (Step-by-step)
1. `open ClaudeRTL.xcodeproj` → Run (⌘R). التطبيق يفضل في الـ menu bar (مفيش Dock).
2. أول تشغيل: بوب-أب Accessibility → فعّل ClaudeRTL في System Settings ▸ Privacy ▸ Accessibility. أعد التشغيل.
3. **اختبار التحديد:** افتح Claude، علّم على فقرة عربية فيها إنجليزي وكود → لازم يظهر بالون عند المؤشّر، النص مظبوط RTL والكود LTR.
4. **اختبار عدم التعليق:** والبالون ظاهر، دوس على عنصر في Claude **بره** البالون → البالون يقفل فورًا، والكليك يوصل لـ Claude عادي (مفيش تعليق).
5. **اختبار الزراير:** دوس "نسخ" → النص في الحافظة. دوس "نُطق" → صوت عربي. دوس × → يقفل.
6. **اختبار الفوكس:** والبالون ظاهر، اكتب في Claude → الكتابة تروح لـ Claude (البالون ما سرقش الفوكس).
7. **اختبار ⌘C fallback:** عطّل إذن Accessibility → انسخ نص عربي بـ ⌘C → لازم يظهر برضه.

---

## 10. Definition of Done (DoD)
- [ ] البالون بيظهر بمجرد تحديد نص عربي في Claude (مع الإذن) وبـ ⌘C من غيره.
- [ ] **مفيش تعليق إطلاقًا**: كليك بره البالون يوصل للتطبيق تحته ويقفل البالون.
- [ ] الزراير الـ3 (نسخ/نُطق/إغلاق) شغّالة من أول كليك.
- [ ] البالون مبياخدش الفوكس من Claude.
- [ ] Markdown + RTL + كود LTR متطابق مع تصميم البروتوتايب.
- [ ] التطبيق menu-bar فقط، بيشتغل عند بدء النظام (اختياري من القايمة).
- [ ] الحافظة بترجع زي ما كانت بعد التقاط التحديد.
- [ ] يبني ويشتغل على macOS 12+ من غير crashes.

---

## 11. Packaging & النشر (لما نبقى مبسوطين)
- وقّع بـ Developer ID + فعّل Hardened Runtime مع استثناء للـ event tap.
- Entitlements: Accessibility عبر طلب الإذن وقت التشغيل (مش entitlement ملف).
- `notarytool` للتوثيق، وبعدين `stapler staple`.
- اعمل **DMG** بخلفية وسحب لـ Applications، أو Sparkle للتحديثات التلقائية.
- صفحة هبوط بسيطة على grwlab.net + فيديو ديمو.

> ملاحظة: الـ event tap + Accessibility ممكن يخلّوا مراجعة الـ App Store صعبة،
> فالأنسب توزيع مباشر (DMG موقّع وموثّق) — وده كفاية تمامًا للنشر اللي إنت عايزه.
