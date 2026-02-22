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
        view.framebufferOnly = false
        
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
        self.renderer = Renderer(device: device, textureName: "texture", extensionName: "jpg")
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {
            return
        }
        renderer.draw(drawable: drawable)
    }
}

class Renderer {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var texture: MTLTexture?
    
    init(device: MTLDevice, textureName: String, extensionName: String) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        let textureLoader = MTKTextureLoader(device: device)
        let url = Bundle.module.url(forResource: textureName, withExtension: extensionName)
        do {
            self.texture = try textureLoader.newTexture(URL: url!)
        } catch {
            print("Failed to load texture: \(textureName).\(extensionName)")
        }
    }
    
    func draw(drawable : CAMetalDrawable) {
        guard
            let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let blitEncoder = commandBuffer.makeBlitCommandEncoder(),
            let texture = self.texture
        else {
            return
        }
        
        let w = min(texture.width, drawable.texture.width)
        let h = min(texture.height, drawable.texture.height)
        
        blitEncoder.copy(from: texture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(w, h, texture.depth),
                         to: drawable.texture,
                         destinationSlice: 0,
                         destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
