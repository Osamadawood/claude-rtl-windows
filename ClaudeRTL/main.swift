import AppKit

UserDefaults.standard.set(["ar"], forKey: "AppleLanguages")

let app = NSApplication.shared
app.userInterfaceLayoutDirection = .rightToLeft
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)   // menu-bar only, no Dock
app.run()
