# Claude RTL for Windows — Build Spec v1.0

> **الهدف:** نسخة ويندوز مطابقة لتطبيق ماك (Claude RTL) — تُصلِح اتجاه النص العربي (RTL) داخل تطبيق **Claude** لسطح المكتب لحظة نسخه، مع تنسيق **Markdown**، إبقاء الكود **LTR**، وقراءة صوتية مع **تمييز الكلمة الحالية**. التطبيق **مجاني، محلي بالكامل، بدون توقيع**.

> **مبدأ التنفيذ:** Cursor ينفّذ **Increment واحد في كل مرة**، ويوقف بعد كل واحد لمراجعة الاختبار والـ DoD قبل ما يكمّل.

---

## 1) الستاك والمبادئ
- **.NET 8 (LTS)** + **C#** + **WPF**.
- **WebView2** لعرض البالون (إعادة استخدام `bubble.html` و`onboarding.html` من نسخة الماك).
- تطبيق **Tray** (بدون نافذة رئيسية)، يشتغل في الخلفية.
- **لا يحتاج أي صلاحيات خاصة** — الكليبورد والهوتكي بيشتغلوا على ويندوز من غير إذن (بخلاف الماك اللي محتاج Accessibility).
- يدعم **Windows 10 (1809+) و Windows 11**، معماريّة **x64** (و arm64 لاحقًا اختياري).

## 2) الحزم (NuGet)
- `Microsoft.Web.WebView2`
- `Hardcodet.NotifyIcon.Wpf` (أيقونة ومنيو الـ tray)
- `System.Speech` (القراءة الصوتية مع أحداث حدود الكلمات)
- Win32 interop يدوي عبر **P/Invoke** (متابعة الكليبورد + النافذة الأمامية + موضع المؤشر)

## 3) بنية المشروع (موازية للماك)
```
ClaudeRTL.Windows/
  App.xaml / App.xaml.cs        // نقطة الدخول، إنشاء الـ tray، دورة الحياة، ShutdownMode=OnExplicitShutdown
  TrayIcon.cs                   // NotifyIcon + قائمة (حول / إعادة الشرح / تشغيل عند البدء / خروج)
  ClipboardMonitor.cs           // AddClipboardFormatListener + قراءة النص المنسوخ
  ForegroundAppWatcher.cs       // GetForegroundWindow -> اسم العملية (claude/anthropic)
  BubbleWindow.xaml / .cs       // نافذة borderless topmost تستضيف WebView2
  WebBridge.cs                  // الجسر JS <-> C# (ExecuteScriptAsync / WebMessageReceived)
  SpeechService.cs              // SpeechSynthesizer + حدث SpeakProgress (تمييز الكلمة)
  Settings.cs                   // حفظ الإعدادات (JSON في %AppData%\ClaudeRTL) + تشغيل عند البدء
  Resources/bubble.html         // منقول من الماك (مع تعديل الجسر)
  Resources/onboarding.html     // منقول من الماك (نص ويندوز)
  Resources/AppIcon.ico         // أيقونة التطبيق
```

## 4) خريطة المكافئات (ماك → ويندوز)
| الوظيفة | ماك (الحالي) | ويندوز (المطلوب) |
|---|---|---|
| الأيقونة | `NSStatusItem` (menu bar) | `NotifyIcon` (system tray) |
| التحديد | ⌘C + متابعة الكليبورد | **Ctrl+C** + `AddClipboardFormatListener` |
| كشف Claude | `NSWorkspace.frontmostApplication` | `GetForegroundWindow` + اسم العملية |
| البالون | `NSPanel` + `WKWebView` | `Window` (topmost, borderless) + `WebView2` |
| الجسر | `WKScriptMessageHandler` / `evaluateJavaScript` | `webview.postMessage` / `ExecuteScriptAsync` |
| القراءة | `AVSpeechSynthesizer` + `willSpeakRange` | `System.Speech` + حدث `SpeakProgress` |
| تشغيل عند البدء | LoginItem | مفتاح `HKCU\...\CurrentVersion\Run` |
| إذن خاص | Accessibility (مطلوب) | **لا يوجد** |

## 5) ⚠️ ملاحظة مهمة — جسر WebView (لازم Cursor ياخد باله)
في الماك `bubble.html` بينادي native عبر `window.webkit.messageHandlers`، و native بينادي JS عبر `evaluateJavaScript`.
في **WebView2** المكافئ:
- **C# → JS:** `await webView.CoreWebView2.ExecuteScriptAsync("renderText(\"...\")")`
- **JS → C#:** `window.chrome.webview.postMessage({...})` ويُقرأ في حدث `CoreWebView2.WebMessageReceived`.

**المطلوب:** تعديل `bubble.html` بحيث يكتشف البيئة ويستخدم الجسر الصح، أو إضافة طبقة `bridge` موحّدة فيها دالتين: `sendToHost(msg)` و`onHostMessage(handler)` — بحيث يشتغل نفس الملف على الماك والويندوز.

---

## 6) الـ Increments

### Increment 1 — الهيكل + Tray + خروج
**المطلوب:**
- مشروع WPF (.NET 8) باسم `ClaudeRTL`، **بدون نافذة رئيسية** (`ShutdownMode=OnExplicitShutdown`، بدون `StartupUri`).
- أيقونة في الـ tray (`AppIcon.ico`) مع tooltip "Claude RTL".
- قائمة يمين-كليك: **حول** / **إعادة الشرح** (placeholder) / **تشغيل عند بدء النظام** (toggle) / **خروج**.
- "خروج" يقفل التطبيق فعليًا ويشيل الأيقونة.

**How to Test:**
1. شغّل التطبيق → تظهر أيقونة في الـ tray، ومفيش نافذة.
2. يمين-كليك → القائمة بكل العناصر الأربعة.
3. اضغط "خروج" → التطبيق يقفل والأيقونة تختفي.

**DoD:** تطبيق tray شغّال بقائمة كاملة وخروج فعّال، بدون أي نافذة عند البدء.

---

### Increment 2 — الكليبورد + gating + إظهار البالون بالنص (plain)
**المطلوب:**
- `ClipboardMonitor`: استخدم `AddClipboardFormatListener` (P/Invoke) للتنبّه عند تغيّر الكليبورد، ثم اقرأ `Clipboard.GetText()`.
- `ForegroundAppWatcher`: `GetForegroundWindow` → `GetWindowThreadProcessId` → اسم العملية؛ اعتبره Claude لو الاسم يحتوي "claude" أو "anthropic".
- **شرط الإظهار:** تغيّر الكليبورد **+** التطبيق الأمامي Claude **+** النص يحتوي حروفًا عربية (نطاق يونيكود `\u0600-\u06FF`) → اعرض `BubbleWindow` بالنص (مبدئيًا نص خام).
- **منع copy-jump:** تجاهل تغييرات الكليبورد الناتجة عن نسخ التطبيق نفسه (تتبّع آخر نص/تسلسل عرضته).

**How to Test:**
1. افتح Claude، حدّد نصًا عربيًا واضغط Ctrl+C → يظهر البالون بالنص.
2. حدّد نصًا في تطبيق آخر واضغط Ctrl+C → **لا يظهر** البالون.
3. انسخ نصًا إنجليزيًا بحتًا داخل Claude → **لا يظهر** (لا يوجد عربي).

**DoD:** البالون يظهر فقط مع نص عربي منسوخ **داخل Claude**، وبدون قفزات تكرار.

---

### Increment 3 — RTL/Markdown/كود LTR (إعادة استخدام bubble.html)
**المطلوب:**
- ضع `bubble.html` (من الماك) في `Resources`، وعدّل الجسر لـ WebView2 (حسب القسم 5).
- `BubbleWindow` يحمّل `bubble.html` في WebView2، ويستدعي دالة العرض (مثلاً `renderText(text)`) بالنص المنسوخ.
- `bubble.html` كما هو يتولّى: اتجاه RTL، تنسيق Markdown، إبقاء الكود LTR، والثيم.

**How to Test:**
1. انسخ في Claude نصًا عربيًا فيه Markdown (عنوان + قائمة) وكلمة كود → البالون يعرضه RTL سليم، Markdown متنسّق، والكود LTR.
2. جرّب أرقامًا وكلمات إنجليزية داخل العربي → تظهر في أماكنها الصحيحة.

**DoD:** نفس عرض الماك بالظبط داخل WebView2.

---

### Increment 4 — القراءة الصوتية + تمييز الكلمة
**المطلوب:**
- `SpeechService` باستخدام `SpeechSynthesizer`؛ اختر صوتًا عربيًا لو متاح (وإلا الافتراضي).
- زر تشغيل/إيقاف في `bubble.html` يبعت رسالة لـ C# (`postMessage`) → يبدأ/يوقف القراءة (toggle حقيقي).
- اربط حدث `SpeakProgress` (يعطي موضع/حدود الكلمة الحالية) → ابعت الموضع لـ JS عبر `ExecuteScriptAsync` → `bubble.html` يلوّن الكلمة الحالية (نفس منطق الماك).
- لو لا يوجد صوت عربي مثبّت → رسالة لطيفة "ثبّت حزمة صوت عربية من إعدادات ويندوز" بدل ما يكراش.

**How to Test:**
1. اضغط تشغيل → يقرأ النص بصوت، والكلمة الحالية تتلوّن أثناء نطقها.
2. اضغط إيقاف → يقف فورًا.
3. على جهاز بدون صوت عربي → تظهر الرسالة بدل التعطّل.

**DoD:** قراءة صوتية مع تمييز كلمة-بكلمة، وتشغيل/إيقاف نظيف.

---

### Increment 5 — الموضع + edge clamping + light/dark + منع copy-jump
**المطلوب:**
- اعرض البالون قرب مؤشر الماوس (`GetCursorPos`) مع **edge clamping** (لا يخرج عن حدود الشاشة، مع مراعاة DPI/شاشات متعددة).
- النافذة **topmost** بدون border، **تختفي عند الضغط خارجها** (deactivate) — بدون أي auto-close timer.
- ثيم **فاتح/داكن** يتبع ويندوز (أو إعداد يدوي).

**How to Test:**
1. حدّد قرب حواف الشاشة → البالون يبقى داخل الشاشة بالكامل.
2. اضغط خارج البالون → يختفي.
3. غيّر ثيم ويندوز (فاتح/داكن) → ألوان البالون تتبع.

**DoD:** تموضع ذكي + clamping + ثيم + إخفاء عند الخروج، وثبات منع التكرار.

---

### Increment 6 — onboarding أول تشغيل + إعدادات + تشغيل عند البدء
**المطلوب:**
- **أول تشغيل:** نافذة onboarding (`onboarding.html` في WebView2) تشرح بإيجاز: «حدّد نصًا عربيًا في Claude واضغط Ctrl+C» — **بدون أي ذكر لإذن Accessibility** (مش محتاجينه على ويندوز).
- إعداد **"تشغيل عند بدء النظام"** (toggle في قائمة الـ tray) → كتابة/حذف في `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
- حفظ الإعدادات في ملف JSON داخل `%AppData%\ClaudeRTL`.

**How to Test:**
1. أول تشغيل (أو بعد مسح الإعدادات) → تظهر نافذة onboarding بنص ويندوز الصحيح.
2. فعّل "تشغيل عند البدء"، أعد تشغيل الجهاز → التطبيق يفتح تلقائيًا في الـ tray. ألغِ التفعيل → لا يفتح.

**DoD:** onboarding صحيح لأول مرة، وإعداد تشغيل-عند-البدء يعمل في الاتجاهين، والإعدادات تُحفظ.

---

### Increment 7 — التغليف والتوزيع (مجاني / بدون توقيع)
**المطلوب:**
- بناء **self-contained single-file**:
  `dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true`
- إدراج أيقونة `.ico` للتطبيق والملف التنفيذي.
- **WebView2 Runtime:** Evergreen موجود غالبًا على Win11؛ للـ Win10 إمّا تضمين الـ bootstrapper أو إضافة فحص يطلب تثبيت الـ Runtime عند أول تشغيل.
- **مثبّت** عبر **Inno Setup** (سكربت `.iss`): ينسخ إلى `Program Files`، ينشئ اختصارًا، وخيار تشغيل-عند-البدء.
- **بدون توقيع** (لا شهادة).

**How to Test:**
1. ثبّت الناتج على جهاز ويندوز نضيف.
2. هيظهر **SmartScreen** → اضغط **More info → Run anyway**.
3. التطبيق يثبّت ويظهر في الـ tray ويشتغل كامل.

**DoD:** مثبّت شغّال بدون توقيع، يعمل بعد تخطّي SmartScreen، والتطبيق كامل الوظائف.

---

## 7) التوزيع (مجاني)
- **بدون توقيع** عمدًا (تطبيق مجاني). المستخدم سيرى تحذير **SmartScreen** → نوفّر له **دليل تثبيت مصوّر** في صفحة التحميل («More info → Run anyway») + **رابط فحص VirusTotal** للطمأنينة.
- السمعة تتحسّن تلقائيًا مع تزايد التحميلات.
- لاحقًا (اختياري) يمكن دراسة نشر التطبيق على **Microsoft Store** لإزالة التحذير دون شهادة مدفوعة — مع التأكد من توافق أداة tray/clipboard مع سياسات الستور.

## 8) فروق متوقعة عن الماك (للعلم)
- **لا يوجد إذن Accessibility** — التحديد عبر Ctrl+C يعمل مباشرة.
- **الصوت العربي** قد يحتاج المستخدم لتثبيت حزمة لغة من إعدادات ويندوز.
- **بدون توقيع** (تحذير SmartScreen).
- باقي التجربة (البالون، RTL، Markdown، الكود LTR، القراءة مع التمييز، الثيم) **مطابقة للماك**.

## 9) أصول يُعاد استخدامها من ريبو الماك
- `bubble.html` (مع تعديل الجسر — القسم 5)
- `onboarding.html` (مع تعديل النص لويندوز)
- لوحة الألوان/الهوية ونصوص الواجهة (نفسها)
