# Claude RTL — Increment 2 (Polish, Permissions & Onboarding)

> سبيك لـ Cursor. كل بند فيه: التنفيذ + خطوات اختبار + DoD.
> يبني فوق النسخة الحالية الشغّالة.

---

## 1) Speech — تشغيل/إيقاف (toggle)
**المشكلة:** الصوت مينفعش يتوقف.
**التنفيذ (`Speech.swift`):**
- اعمله singleton `Speech.shared` بـ `private let synth = AVSpeechSynthesizer()` ويتبنّى `AVSpeechSynthesizerDelegate`.
- `func toggle(_ text: String)`:
  - لو `synth.isSpeaking` → `synth.stopSpeaking(at: .immediate)`.
  - غير كده → اعمل `AVSpeechUtterance` بصوت `AVSpeechSynthesisVoice(language: "ar-SA")` (fallback أول صوت يبدأ بـ "ar")، وبعدها `synth.speak(u)`.
- delegate: `didFinish` و `didCancel` → بلّغ البانل إنه وقف.
- لما تبدأ/تقف، نادِ JS في الـ webview: `window.setSpeaking(true|false)`.
**جسر/HTML:** زرار الصوت يبعت `bridge.postMessage({action:"speak"})`، و`window.setSpeaking(b)` يبدّل الأيقونة بين ▶ و ⏸.
**اختبار:** اضغط الصوت → يقرأ. اضغط تاني وهو بيقرأ → يقف فورًا والأيقونة ترجع ▶. اقفل البالون وهو بيقرأ → الصوت يقف.
**DoD:** الزرار toggle حقيقي (يشغّل/يوقف)، والأيقونة بتعكس الحالة.

---

## 2) ظهور البالون في مكان واضح دايمًا (clamping)
**المشكلة:** بيتقصّ في حواف الشاشة (فوق/جنب).
**التنفيذ (`BubblePanel.show(at point:)`):**
- `let screen = NSScreen.screens.first { $0.frame.contains(point) } ?? NSScreen.main!`
- استخدم `let vf = screen.visibleFrame` (بيستثني الـ menu bar والـ Dock).
- احسب origin المبدئي تحت المؤشّر بإزاحة بسيطة، وبعدين **clamp** بهامش 12px:
  - `x = min(max(x, vf.minX + 12), vf.maxX - panelW - 12)`
  - لو مفيش مكان تحت المؤشّر، اقلبه **فوق** المؤشّر، وبدّل اتجاه السهم (arrow) في الـ HTML (كلاس `.arrow.bottom`).
  - clamp الـ y جوه `vf` برضه.
- خلّي بالك من تحويل إحداثيات الماوس (top-left من CGEvent) لإحداثيات AppKit (bottom-left) قبل الـ clamp.
**اختبار:** علّم نص قريب من أعلى/يمين/يسار/أسفل الشاشة → البالون يفضل **ظاهر بالكامل** جوه الشاشة في كل الحالات، والسهم يشاور ناحية المصدر.
**DoD:** مفيش أي حالة البالون يتقصّ أو يطلع بره الشاشة.

---

## 3) سحب البالون وتحريكه
**التنفيذ:** WKWebView بيبلع أحداث الماوس، فـ `isMovableByWindowBackground` لوحده مش كفاية.
- اعمل `final class DragHandle: NSView { override func mouseDown(with e: NSEvent) { window?.performDrag(with: e) } }`.
- حط `DragHandle` شفّاف **فوق شريط الهيدر** (المساحة الفاضية حوالين كلمة Claude RTL، **مش** فوق الزراير) كـ subview أعلى الـ webview.
- `panel.isMovable = true`.
**اختبار:** اسحب من منطقة الهيدر → البالون يتحرك لأي مكان. الزراير لسه بتتدوس عادي.
**DoD:** يتسحب بسلاسة من الهيدر من غير ما يعطّل الزراير.

---

## 4) الأيقونات
- **App icon:** PNG 1024×1024 → `Assets.xcassets ▸ AppIcon` (Single Size).
- **Menu-bar icon:** PNG أحادي اللون (أسود + شفافية) 18×18 و 36×36 → `Assets` باسم `MenuBarIcon`. في `AppDelegate`:
```swift
if let img = NSImage(named: "MenuBarIcon") {
    img.isTemplate = true            // مهم: عشان يتلوّن تلقائي مع الوضع الفاتح/الداكن
    statusItem.button?.image = img
} else {
    statusItem.button?.title = "ع"
}
```
**DoD:** أيقونة التطبيق ظاهرة في Finder/Dock، وأيقونة الـ menu bar ظاهرة وواضحة وبتتلوّن صح.

---

## 5) التشغيل التلقائي مع بدء النظام
**التنفيذ (`Settings.swift`):** `import ServiceManagement`
- `func setLaunchAtLogin(_ on: Bool)`:
  - `on ? try? SMAppService.mainApp.register() : try? SMAppService.mainApp.unregister()`
  - احفظ النية في `UserDefaults`، واعرض الحالة من `SMAppService.mainApp.status`.
- ضيف Toggle في قايمة الـ menu bar: "تشغيل عند بدء النظام".
**ملاحظة:** بيشتغل بثبات لما التطبيق يكون **موقّع وفي /Applications**. من DerivedData ممكن يبقى متقطّع — نأكّده بعد التغليف.
**اختبار:** فعّل التوجل، اعمل logout/login → التطبيق بيفتح لوحده في الـ menu bar.
**DoD:** التوجل بيسجّل/يلغي login item، وبيعكس الحالة الصح.

---

## 6) شاشة الترحيب (Onboarding) + الخصوصية والصلاحيات
**التنفيذ:** أول تشغيل (`UserDefaults.bool(forKey:"didOnboard") == false`):
- افتح `NSWindow` (titled, ~520×640) فيها `WKWebView` بتحمّل `onboarding.html` بنفس تصميم GRW.
- المحتوى: عنوان + وصف قصير (إيه اللي بيعمله) + **الخصوصية**: "كل حاجة بتشتغل محليًا على جهازك، مفيش أي بيانات بتتبعت لأي مكان" + **الصلاحيات**: "محتاج إذن Accessibility عشان يكتشف التحديد" + زرارين:
  - "افتح إعدادات Accessibility" → bridge action يفتح:
    `NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)`
  - "ابدأ" → يقفل النافذة ويحط `didOnboard = true`.
- ضيف في قايمة الـ menu bar بند "حول / إعادة الشرح" يفتح نفس النافذة.
**اختبار:** أول تشغيل تظهر الشاشة؛ "افتح الإعدادات" يفتح لوحة Accessibility؛ "ابدأ" يقفلها ومتظهرش تاني؛ بند القايمة يعيد فتحها.
**DoD:** Onboarding بيظهر مرة واحدة، الأزرار شغّالة، والنصوص واضحة (وصف + خصوصية + صلاحيات).

---

## ملاحظة للنشر (مش دلوقتي)
- عشان ميزة "الظهور بمجرد التحديد" (CGEventTap) تشتغل عند الناس: **App Sandbox = OFF**، **Hardened Runtime = ON**، توقيع **Developer ID**، ثم **notarize** و**DMG**. (مش App Store.)
