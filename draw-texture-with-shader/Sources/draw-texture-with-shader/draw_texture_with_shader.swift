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
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let texCoordBuffer: MTLBuffer
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    private var texture: MTLTexture?
    
    private static let vertexData: [Float] = [-1, -1, 0, 1,
                                               1, -1, 0, 1,
                                              -1,  1, 0, 1,
                                               1,  1, 0, 1]
    private static let texCordData: [Float] = [0, 1,
                                               1, 1,
                                               0, 0,
                                               1, 0]
    
    private static let shader: String = """
    #include <metal_stdlib>
    using namespace metal;
    
    struct Vertex {
        float4 position [[position]];
        float2 texCoords;
    };
    
    vertex Vertex vertex_function(constant float4* positions [[buffer(0)]],
                                  constant float2* texCoords [[buffer(1)]],
                                  uint vid [[vertex_id]]) {
        Vertex out;
        out.position = positions[vid];
        out.texCoords = texCoords[vid];
        return out;
    }
    
    fragment float4 fragment_function(Vertex in [[stage_in]], texture2d<float> texture [[texture(0)]]) {
        constexpr sampler sampler;
        
        return texture.sample(sampler, in.texCoords);
    }
    """
    
    init(device: MTLDevice, textureName: String, extensionName: String) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        let library = try! device.makeLibrary(source: Renderer.shader, options: nil)
        let vertexFunction = library.makeFunction(name: "vertex_function")!
        let fragmentFunction = library.makeFunction(name: "fragment_function")!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        let textureLoader = MTKTextureLoader(device: device)
        let url = Bundle.module.url(forResource: textureName, withExtension: extensionName)
        do {
            self.texture = try textureLoader.newTexture(URL: url!)
        } catch {
            print("Failed to load texture: \(textureName).\(extensionName)")
        }
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        self.pipelineState = try! self.device.makeRenderPipelineState(descriptor: pipelineDescriptor)

        let vertexDataSize = MemoryLayout<Float>.size * Renderer.vertexData.count
        self.vertexBuffer = device.makeBuffer(bytes: Renderer.vertexData, length: vertexDataSize)!
        let textCordDataSize = MemoryLayout<Float>.size * Renderer.texCordData.count
        self.texCoordBuffer = device.makeBuffer(bytes: Renderer.texCordData, length: textCordDataSize)!
        
        self.renderPassDescriptor.colorAttachments[0].loadAction = .clear
        self.renderPassDescriptor.colorAttachments[0].storeAction = .store
        self.renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func draw(drawable : CAMetalDrawable) {
        self.renderPassDescriptor.colorAttachments[0].texture = drawable.texture

        guard
            let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: self.renderPassDescriptor),
            let texture = self.texture
        else {
            return
        }

        renderCommandEncoder.setRenderPipelineState(self.pipelineState)
        renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        renderCommandEncoder.setFragmentTexture(texture, index: 0)
        renderCommandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderCommandEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
