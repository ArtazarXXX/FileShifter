import Cocoa
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Скрываем иконку из Dock, приложение живет только в строке меню
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        checkAccessibilityPermissions()
        
        // Запуск мониторинга
        EventMonitor.shared.start()
        updateStatusMenu()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath.circle.fill", accessibilityDescription: "FileShifter")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "FileShifter — Быстрые файловые действия"
        }
    }
    
    private func updateStatusMenu() {
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "FileShifter: \(EventMonitor.shared.isRunning ? "Активен ✓" : "Приостановлен")", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(
            title: EventMonitor.shared.isRunning ? "Приостановить мониторинг" : "Возобновить мониторинг",
            action: #selector(toggleMonitoring),
            keyEquivalent: "s"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let guideHeader = NSMenuItem(title: "Двойной клик клавиши над файлом (Double-Tap):", action: nil, keyEquivalent: "")
        guideHeader.isEnabled = false
        menu.addItem(guideHeader)
        
        let shiftGuide = NSMenuItem(title: "  ⇧⇧ Shift: Быстрая конвертация (WebP, AVIF, MP4, PDF, MD...)", action: nil, keyEquivalent: "")
        shiftGuide.isEnabled = false
        menu.addItem(shiftGuide)
        
        let ctrlGuide = NSMenuItem(title: "  ⌃⌃ Control: Магия & Инфо (Фон, Сжатие, OCR, HUD, Очистка...)", action: nil, keyEquivalent: "")
        ctrlGuide.isEnabled = false
        menu.addItem(ctrlGuide)
        
        let optGuide = NSMenuItem(title: "  ⌥⌥ Option: Скорость & Оптимизация (0.5x–2.5x, ZIP, Сортировка)", action: nil, keyEquivalent: "")
        optGuide.isEnabled = false
        menu.addItem(optGuide)
        
        let cmdGuide = NSMenuItem(title: "  ⌘⌘ Command: Smart Vision Кроп (9:16, 1:1, A4, Штампы, Base64)", action: nil, keyEquivalent: "")
        cmdGuide.isEnabled = false
        menu.addItem(cmdGuide)
        
        menu.addItem(NSMenuItem.separator())
        
        // Подменю всех возможностей
        let capabilitiesMenu = NSMenu()
        let imageItem = NSMenuItem(title: "📸 Фото: WebP, AVIF, PNG, JPG, Удаление фона, OCR, EXIF, Smart Crop", action: nil, keyEquivalent: "")
        imageItem.isEnabled = false
        capabilitiesMenu.addItem(imageItem)
        
        let videoItem = NSMenuItem(title: "🎬 Видео: MP4, WebM, GIF, MP3, Без звука, Сжатие <25МБ, Скорости 0.5x-2.5x, Кроп 9:16", action: nil, keyEquivalent: "")
        videoItem.isEnabled = false
        capabilitiesMenu.addItem(videoItem)
        
        let pdfDocItem = NSMenuItem(title: "📑 PDF и Документы: PNG-страницы, Текст, Markdown, A4, Штампы, Слияние, DOCX", action: nil, keyEquivalent: "")
        pdfDocItem.isEnabled = false
        capabilitiesMenu.addItem(pdfDocItem)
        
        let dataItem = NSMenuItem(title: "📊 Данные: JSON, YAML, CSV, Plist, Таблицы, Base64, Сортировка, Дедупликация", action: nil, keyEquivalent: "")
        dataItem.isEnabled = false
        capabilitiesMenu.addItem(dataItem)
        
        let capabilitiesItem = NSMenuItem(title: "Все поддерживаемые форматы и действия", action: nil, keyEquivalent: "")
        capabilitiesItem.submenu = capabilitiesMenu
        menu.addItem(capabilitiesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let permItem = NSMenuItem(title: "Проверить права Доступности (Accessibility)...", action: #selector(checkAccessibility), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)
        
        let docItem = NSMenuItem(title: "Документация проекта (ROADMAP)...", action: #selector(openDocumentation), keyEquivalent: "d")
        docItem.target = self
        menu.addItem(docItem)
        
        let githubItem = NSMenuItem(title: "Репозиторий проекта на GitHub...", action: #selector(openGitHub), keyEquivalent: "g")
        githubItem.target = self
        menu.addItem(githubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Выход из FileShifter", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func toggleMonitoring() {
        if EventMonitor.shared.isRunning {
            EventMonitor.shared.stop()
        } else {
            EventMonitor.shared.start()
        }
        updateStatusMenu()
    }
    
    private var accessTimer: Timer?
    
    @objc private func checkAccessibility() {
        let trusted = AXIsProcessTrusted()
        if trusted {
            OverlayWindowController.shared.showToast(message: "Права Доступности предоставлены ✓", icon: "checkmark.seal.fill", at: NSEvent.mouseLocation)
        } else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("[FileShifter] Внимание: Для перехвата глобальных клавиш требуются права в Настройки -> Конфиденциальность -> Универсальный доступ (Accessibility)")
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            
            accessTimer?.invalidate()
            accessTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                Task { @MainActor in
                    if AXIsProcessTrusted() {
                        timer.invalidate()
                        print("[FileShifter] Права Доступности успешно получены!")
                        EventMonitor.shared.start()
                        self?.updateStatusMenu()
                        OverlayWindowController.shared.showToast(
                            message: "FileShifter: Доступ предоставлен ✓",
                            icon: "checkmark.seal.fill",
                            at: NSEvent.mouseLocation
                        )
                    }
                }
            }
        }
    }
    
    @objc private func openDocumentation() {
        let fileManager = FileManager.default
        let localRoadmap = URL(fileURLWithPath: fileManager.currentDirectoryPath).appendingPathComponent("ROADMAP.md")
        if fileManager.fileExists(atPath: localRoadmap.path) {
            NSWorkspace.shared.open(localRoadmap)
            return
        }
        
        if let bundleDoc = Bundle.main.url(forResource: "ROADMAP", withExtension: "md") {
            NSWorkspace.shared.open(bundleDoc)
            return
        }
        
        openGitHub()
    }
    
    @objc private func openGitHub() {
        if let githubURL = URL(string: "https://github.com/artem/FileShifter") {
            NSWorkspace.shared.open(githubURL)
        }
    }
    
    @objc private func quitApp() {
        EventMonitor.shared.stop()
        NSApp.terminate(nil)
    }
}
