import Cocoa
import Foundation

@MainActor
public final class EventMonitor {
    public static let shared = EventMonitor()
    
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var mouseMoveTimer: Timer?
    
    private var isShiftDown = false
    private var isControlDown = false
    private var isCommandDown = false
    private var isOptionDown = false
    private var isWheelVisible = false
    
    private var lastShiftTapTime: Date = .distantPast
    private var lastControlTapTime: Date = .distantPast
    private var lastCommandTapTime: Date = .distantPast
    private var lastOptionTapTime: Date = .distantPast
    private let doubleTapThreshold: TimeInterval = 0.38
    private var isHoldingModifierAfterDoubleTap = false
    
    private var centerLocation: CGPoint = .zero
    private var currentMode: WheelMode?
    private var activeFile: SelectedFile?
    private var currentSelectedIndex: Int?
    
    public private(set) var isRunning = false
    
    private init() {}
    
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event: event)
            }
        }
        
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event: event)
            }
            return event
        }
        
        print("[EventMonitor] Мониторинг запущен")
    }
    
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        
        if let g = globalFlagsMonitor { NSEvent.removeMonitor(g); globalFlagsMonitor = nil }
        if let l = localFlagsMonitor { NSEvent.removeMonitor(l); localFlagsMonitor = nil }
        stopMouseTracking()
        OverlayWindowController.shared.hideWheel()
        isWheelVisible = false
        print("[EventMonitor] Мониторинг остановлен")
    }
    
    private func handleFlagsChanged(event: NSEvent) {
        let flags = event.modifierFlags
        let shiftPressed = flags.contains(.shift)
        let controlPressed = flags.contains(.control)
        let commandPressed = flags.contains(.command)
        let optionPressed = flags.contains(.option)
        let now = Date()
        
        // SHIFT -> Convert (Double-tap)
        if shiftPressed && !isShiftDown {
            isShiftDown = true
            let interval = now.timeIntervalSince(lastShiftTapTime)
            if interval < doubleTapThreshold {
                lastShiftTapTime = .distantPast
                isHoldingModifierAfterDoubleTap = true
                tryActivate(mode: .convert)
            } else {
                lastShiftTapTime = now
            }
        } else if !shiftPressed && isShiftDown {
            isShiftDown = false
            handleModifierRelease(mode: .convert)
        }
        
        // CONTROL -> Magic Actions (Double-tap)
        if controlPressed && !isControlDown {
            isControlDown = true
            let interval = now.timeIntervalSince(lastControlTapTime)
            if interval < doubleTapThreshold {
                lastControlTapTime = .distantPast
                isHoldingModifierAfterDoubleTap = true
                tryActivate(mode: .magic)
            } else {
                lastControlTapTime = now
            }
        } else if !controlPressed && isControlDown {
            isControlDown = false
            handleModifierRelease(mode: .magic)
        }
        
        // COMMAND -> Smart Vision Crop (Double-tap)
        if commandPressed && !isCommandDown {
            isCommandDown = true
            let interval = now.timeIntervalSince(lastCommandTapTime)
            if interval < doubleTapThreshold {
                lastCommandTapTime = .distantPast
                isHoldingModifierAfterDoubleTap = true
                tryActivate(mode: .crop)
            } else {
                lastCommandTapTime = now
            }
        } else if !commandPressed && isCommandDown {
            isCommandDown = false
            handleModifierRelease(mode: .crop)
        }
        
        // OPTION -> Speed / Scale (Double-tap)
        if optionPressed && !isOptionDown {
            isOptionDown = true
            let interval = now.timeIntervalSince(lastOptionTapTime)
            if interval < doubleTapThreshold {
                lastOptionTapTime = .distantPast
                isHoldingModifierAfterDoubleTap = true
                tryActivate(mode: .speed)
            } else {
                lastOptionTapTime = now
            }
        } else if !optionPressed && isOptionDown {
            isOptionDown = false
            handleModifierRelease(mode: .speed)
        }
    }
    
    private func handleModifierRelease(mode: WheelMode) {
        if isWheelVisible && currentMode == mode {
            if currentSelectedIndex != nil {
                commitAction()
            } else {
                // Если отпустили клавишу без выбора сектора (в центре/мертвой зоне) — закрываем меню!
                cancelWheel()
            }
        }
    }
    
    private func tryActivate(mode: WheelMode) {
        guard let file = FinderBridge.shared.getSelectedFile() else {
            print("[EventMonitor] tryActivate: в Finder не выбран файл или Finder не активен")
            resetState()
            return
        }
        guard file.isSupported else {
            if file.isCloudStub {
                OverlayWindowController.shared.showToast(message: "Файл в iCloud и не скачан на Mac", icon: "icloud.and.arrow.down", at: centerLocation)
            } else {
                print("[EventMonitor] tryActivate: файл \(file.name) не поддерживается (категория: \(file.category))")
            }
            resetState()
            return
        }
        
        print("[EventMonitor] Активация меню: mode=\(mode), file=\(file.name)")
        self.activeFile = file
        self.currentMode = mode
        self.centerLocation = NSEvent.mouseLocation
        self.currentSelectedIndex = nil
        self.isWheelVisible = true
        
        OverlayWindowController.shared.showWheel(
            mode: mode,
            category: file.category,
            selectedIndex: nil,
            fileName: file.name,
            at: centerLocation
        )
        
        startMouseTracking()
    }
    
    private func startMouseTracking() {
        stopMouseTracking()
        
        mouseMoveTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.trackMouseMovement()
            }
        }
        
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseClick(event: event)
            }
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.handleMouseClick(event: event)
            }
            return event
        }
        
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                if event.keyCode == 53 { // Escape key
                    self?.cancelWheel()
                }
            }
        }
        
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                if event.keyCode == 53 { // Escape key
                    self?.cancelWheel()
                }
            }
            return event
        }
    }
    
    private func stopMouseTracking() {
        mouseMoveTimer?.invalidate()
        mouseMoveTimer = nil
        if let g = globalMouseMonitor { NSEvent.removeMonitor(g); globalMouseMonitor = nil }
        if let l = localMouseMonitor { NSEvent.removeMonitor(l); localMouseMonitor = nil }
        if let gk = globalKeyMonitor { NSEvent.removeMonitor(gk); globalKeyMonitor = nil }
        if let lk = localKeyMonitor { NSEvent.removeMonitor(lk); localKeyMonitor = nil }
    }
    
    private func handleMouseClick(event: NSEvent) {
        guard isWheelVisible else { return }
        if currentSelectedIndex != nil {
            commitAction()
        } else {
            cancelWheel()
        }
    }
    
    private func cancelWheel() {
        stopMouseTracking()
        OverlayWindowController.shared.hideWheel()
        resetState()
    }
    
    private func trackMouseMovement() {
        guard let mode = currentMode, let file = activeFile, isWheelVisible else { return }
        
        let currentMouse = NSEvent.mouseLocation
        let dx = currentMouse.x - centerLocation.x
        let dy = -(currentMouse.y - centerLocation.y)
        
        let distance = hypot(dx, dy)
        let deadZone: CGFloat = RadialMenuView.innerRadius
        
        let newIndex: Int?
        if distance < deadZone {
            newIndex = nil
        } else {
            let sectors = RadialMenuView.getSectors(mode: mode, category: file.category, fileName: file.name)
            let count = sectors.count
            guard count > 0 else {
                newIndex = nil
                return
            }
            
            let slice = 360.0 / Double(count)
            let rawAngle = atan2(dy, dx) * 180.0 / .pi
            var normalizedAngle = rawAngle + 90.0
            if normalizedAngle < 0 {
                normalizedAngle += 360.0
            }
            
            let sector = Int((normalizedAngle + slice / 2.0).truncatingRemainder(dividingBy: 360.0) / slice)
            newIndex = sector < count ? sector : 0
        }
        
        if newIndex != currentSelectedIndex {
            currentSelectedIndex = newIndex
            OverlayWindowController.shared.updateWheelSelection(
                mode: mode,
                category: file.category,
                selectedIndex: newIndex,
                fileName: file.name
            )
            
            if newIndex != nil {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
        }
    }
    
    private func commitAction() {
        stopMouseTracking()
        OverlayWindowController.shared.hideWheel()
        isWheelVisible = false
        
        guard let mode = currentMode,
              let selectedIndex = currentSelectedIndex,
              let file = activeFile else {
            resetState()
            return
        }
        
        let sectors = RadialMenuView.getSectors(mode: mode, category: file.category, fileName: file.name)
        guard selectedIndex >= 0 && selectedIndex < sectors.count else {
            resetState()
            return
        }
        
        let sector = sectors[selectedIndex]
        let finishLocation = NSEvent.mouseLocation
        
        ActionExecutor.shared.execute(action: sector.action, for: file, at: finishLocation)
        
        resetState()
    }
    
    private func resetState() {
        currentMode = nil
        activeFile = nil
        currentSelectedIndex = nil
        isWheelVisible = false
    }
}
