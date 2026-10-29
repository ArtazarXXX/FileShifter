import Cocoa
import SwiftUI

@MainActor
public final class OverlayWindowController: ObservableObject {
    public static let shared = OverlayWindowController()
    
    private var window: NSPanel?
    private var toastWindow: NSPanel?
    private var infoWindow: NSPanel?
    private var dismissTimer: Timer?
    private var infoDismissTimer: Timer?
    
    private let wheelState = RadialMenuState()
    
    private init() {
        setupWheelWindow()
        setupToastWindow()
        setupInfoWindow()
    }
    
    private func makeOverlayPanel(width: CGFloat, height: CGFloat) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        return panel
    }
    
    private func setupWheelWindow() {
        let panel = makeOverlayPanel(width: 440, height: 440)
        panel.contentView = NSHostingView(rootView: RadialMenuView(state: self.wheelState))
        self.window = panel
    }
    
    private func setupToastWindow() {
        self.toastWindow = makeOverlayPanel(width: 320, height: 60)
    }
    
    private func setupInfoWindow() {
        self.infoWindow = makeOverlayPanel(width: 360, height: 260)
    }
    
    public func showWheel(mode: WheelMode, category: FileCategory, selectedIndex: Int?, fileName: String, at location: CGPoint) {
        guard let window = self.window else { return }
        
        wheelState.update(mode: mode, category: category, selectedIndex: selectedIndex, fileName: fileName)
        
        let origin = NSPoint(x: location.x - 220, y: location.y - 220)
        window.setFrameOrigin(origin)
        
        if !window.isVisible {
            window.alphaValue = 0
            window.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.12
                window.animator().alphaValue = 1.0
            }
        }
    }
    
    public func updateWheelSelection(mode: WheelMode, category: FileCategory, selectedIndex: Int?, fileName: String) {
        guard let window = self.window, window.isVisible else { return }
        wheelState.update(mode: mode, category: category, selectedIndex: selectedIndex, fileName: fileName)
    }
    
    public func hideWheel() {
        guard let window = self.window, window.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.1
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
        })
    }
    
    public func showToast(message: String, icon: String = "checkmark.circle.fill", at location: CGPoint) {
        guard let toast = self.toastWindow else { return }
        dismissTimer?.invalidate()
        
        let view = ToastFeedbackView(message: message, icon: icon)
        toast.contentView = NSHostingView(rootView: view)
        
        let origin = NSPoint(x: location.x - 160, y: location.y - 30)
        toast.setFrameOrigin(origin)
        
        toast.alphaValue = 0
        toast.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            toast.animator().alphaValue = 1.0
        }
        
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        NSSound(named: "Glass")?.play()
        
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.95, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideToast()
            }
        }
    }
    
    private func hideToast() {
        guard let toast = self.toastWindow, toast.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            toast.animator().alphaValue = 0
        }, completionHandler: {
            toast.orderOut(nil)
        })
    }
    
    public func presentInfoCard<V: View>(view: V, at location: CGPoint, width: CGFloat = 300, duration: TimeInterval = 3.5) {
        guard let panel = self.infoWindow else { return }
        infoDismissTimer?.invalidate()
        
        panel.contentView = NSHostingView(rootView: view)
        
        let origin = NSPoint(x: location.x - 180, y: location.y - 100)
        panel.setFrameOrigin(origin)
        
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            panel.animator().alphaValue = 1.0
        }
        
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        NSSound(named: "Pop")?.play()
        
        infoDismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.hideInfoCard()
            }
        }
    }
    
    public func showInfoCard(meta: ImageMetadata, at location: CGPoint) {
        presentInfoCard(view: ImageInfoCardView(meta: meta), at: location, width: 290, duration: 3.2)
    }
    
    public func showVideoInfoCard(meta: VideoMetadata, at location: CGPoint) {
        presentInfoCard(view: VideoInfoCardView(meta: meta), at: location, width: 300, duration: 3.5)
    }
    
    public func showDocumentInfoCard(meta: DocumentMetadata, at location: CGPoint) {
        presentInfoCard(view: DocumentInfoCardView(meta: meta), at: location, width: 300, duration: 3.5)
    }
    
    private func hideInfoCard() {
        guard let panel = self.infoWindow, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
