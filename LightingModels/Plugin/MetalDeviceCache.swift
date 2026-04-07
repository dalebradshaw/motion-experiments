import Foundation
import Metal
import FxPlug

// Per-device cache entry — one per (GPU device × pixel format × shader index) triple.
// The template creates one pipeline per device; we extend that to one per shader.

private let kMaxCommandQueues = 5

private class DeviceCacheItem {
    let device:        MTLDevice
    let pipelineState: MTLRenderPipelineState
    let pixelFormat:   MTLPixelFormat
    let shaderIndex:   Int

    private var queues:     [[String: Any]]
    private let queueLock = NSLock()

    init(device: MTLDevice, pixelFormat: MTLPixelFormat, shaderIndex: Int) throws {
        self.device      = device
        self.pixelFormat = pixelFormat
        self.shaderIndex = shaderIndex

        // Command-queue pool
        queues = (0..<kMaxCommandQueues).map { _ in
            ["inUse": false, "queue": device.makeCommandQueue()! as MTLCommandQueue]
        }

        // Load default.metallib (compiled from LightingModels.metal)
        guard let lib = device.makeDefaultLibrary() else {
            throw NSError(domain: "LightingModels", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "No default Metal library"])
        }

        // Vertex function is shared; fragment function dispatches by shader index.
        guard let vf = lib.makeFunction(name: "vertexShader"),
              let ff = lib.makeFunction(name: "fragmentShader") else {
            throw NSError(domain: "LightingModels", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Missing Metal functions"])
        }

        let desc = MTLRenderPipelineDescriptor()
        desc.label                            = "LightingModels_shader\(shaderIndex)"
        desc.vertexFunction                   = vf
        desc.fragmentFunction                 = ff
        desc.colorAttachments[0].pixelFormat  = pixelFormat

        pipelineState = try device.makeRenderPipelineState(descriptor: desc)
    }

    func getQueue() -> MTLCommandQueue? {
        queueLock.lock(); defer { queueLock.unlock() }
        for i in 0..<queues.count {
            if !(queues[i]["inUse"] as! Bool) {
                queues[i]["inUse"] = true
                return queues[i]["queue"] as? MTLCommandQueue
            }
        }
        return nil
    }

    func returnQueue(_ q: MTLCommandQueue) {
        queueLock.lock(); defer { queueLock.unlock() }
        for i in 0..<queues.count {
            if (queues[i]["queue"] as? MTLCommandQueue) === q {
                queues[i]["inUse"] = false; return
            }
        }
    }

    func contains(_ q: MTLCommandQueue) -> Bool {
        return queues.contains { ($0["queue"] as? MTLCommandQueue) === q }
    }
}

class MetalDeviceCache: NSObject {

    static let deviceCache = MetalDeviceCache()

    private var items = [DeviceCacheItem]()
    private let lock  = NSLock()

    // MARK: Public API

    class func fxMTLPixelFormat(for imageTile: FxImageTile) -> MTLPixelFormat {
        switch imageTile.ioSurface.pixelFormat {
        case kCVPixelFormatType_128RGBAFloat: return .rgba32Float
        case kCVPixelFormatType_32BGRA:       return .bgra8Unorm
        default:
            NSLog("LightingModels: unexpected IOSurface format 0x%08x", imageTile.ioSurface.pixelFormat)
            return .rgba16Float
        }
    }

    func device(with registryID: UInt64) -> MTLDevice? {
        return MTLCopyAllDevices().first { $0.registryID == registryID }
    }

    /// Returns (or creates) the shared pipeline for a given device/format/shader triple.
    /// The fragment shader uses shaderIndex via a constant buffer so a single PSO covers all shaders.
    func pipelineState(with registryID: UInt64, pixelFormat: MTLPixelFormat, shaderIndex: Int) -> MTLRenderPipelineState? {
        lock.lock(); defer { lock.unlock() }
        if let existing = items.first(where: {
            $0.device.registryID == registryID &&
            $0.pixelFormat       == pixelFormat &&
            $0.shaderIndex       == shaderIndex
        }) { return existing.pipelineState }

        guard let dev = MTLCopyAllDevices().first(where: { $0.registryID == registryID }) else { return nil }
        return makeItem(device: dev, pixelFormat: pixelFormat, shaderIndex: shaderIndex)?.pipelineState
    }

    func commandQueue(with registryID: UInt64, pixelFormat: MTLPixelFormat) -> MTLCommandQueue? {
        lock.lock(); defer { lock.unlock() }
        // Any item for this device/format will do for a command queue
        if let existing = items.first(where: {
            $0.device.registryID == registryID && $0.pixelFormat == pixelFormat
        }) { return existing.getQueue() }

        guard let dev = MTLCopyAllDevices().first(where: { $0.registryID == registryID }) else { return nil }
        return makeItem(device: dev, pixelFormat: pixelFormat, shaderIndex: 0)?.getQueue()
    }

    func returnCommandQueueToCache(commandQueue q: MTLCommandQueue) {
        lock.lock(); defer { lock.unlock() }
        items.first { $0.contains(q) }?.returnQueue(q)
    }

    // MARK: Private

    @discardableResult
    private func makeItem(device: MTLDevice, pixelFormat: MTLPixelFormat, shaderIndex: Int) -> DeviceCacheItem? {
        do {
            let item = try DeviceCacheItem(device: device, pixelFormat: pixelFormat, shaderIndex: shaderIndex)
            items.append(item)
            return item
        } catch {
            NSLog("LightingModels: failed to create DeviceCacheItem: %@", error.localizedDescription)
            return nil
        }
    }
}
