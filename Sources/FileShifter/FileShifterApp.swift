import Cocoa

@main
struct FileShifterApp {
    private static var strongDelegate: AppDelegate?
    
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--test-video-control") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runVideoControlTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        if CommandLine.arguments.contains("--test-option-speed") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runOptionSpeedTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        if CommandLine.arguments.contains("--test-video-crop") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runVideoCropTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        if CommandLine.arguments.contains("--test-doc-shift") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runDocumentShiftTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        if CommandLine.arguments.contains("--test-doc-control") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runDocumentControlTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        if CommandLine.arguments.contains("--test-doc-option-command") {
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                Task {
                    await TestRunner.runDocumentOptionAndCommandTests()
                    semaphore.signal()
                }
            }
            semaphore.wait()
            return
        }
        
        let app = NSApplication.shared
        let delegate = AppDelegate()
        strongDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}
