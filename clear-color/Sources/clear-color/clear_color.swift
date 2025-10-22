// The Swift Programming Language
// https://docs.swift.org/swift-book
import Cocoa
import MetalKit

@main
class AppDelegate : NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var viewDelegate: ViewDelegate!
    
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not found.")
        }
        let view = MTKView()

        self.window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 512, height: 512), styleMask: [.miniaturizable, .closable, .resizable, .titled], backing: .buffered, defer: false)
        self.viewDelegate = ViewDelegate(device: device)

        view.device = device
        view.delegate = self.viewDelegate
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.clearColor = MTLClearColor(red: 1.0, green: 0, blue: 0, alpha: 1)
        
        self.window.contentView = view
        self.window.makeKeyAndOrderFront(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class ViewDelegate : NSObject, MTKViewDelegate {
    private let renderer: Renderer
    
    init(device: MTLDevice) {
        self.renderer = Renderer(device: device)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        renderer.draw(view: view)
    }
}

struct Renderer {
    private let device: MTLDevice
    private let commnadQueue: MTLCommandQueue
    
    init(device: MTLDevice) {
        self.device = device
        self.commnadQueue = device.makeCommandQueue()!
    }
    
    @MainActor
    func draw(view: MTKView) {
        guard
            let commandBuffer = self.commnadQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let drawable = view.currentDrawable
        else {
            return
        }
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
