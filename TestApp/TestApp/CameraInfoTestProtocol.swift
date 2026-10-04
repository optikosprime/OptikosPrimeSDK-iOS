#if DEBUG
import Foundation
import ObjectiveC

/// Debug-only network adapter: UI fixtures, plus a real-device model override for simulator requests.
final class CameraInfoTestProtocol: URLProtocol {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var requests = 0

    private var forwardingTask: URLSessionDataTask?
    private var forwardingSession: URLSession?

    static func installIfRequested() {
        let fixture = ProcessInfo.processInfo.environment["OPTIKOS_CAMERA_FIXTURE"]
        let defaults = UserDefaults.standard
        // A later manual launch must never reuse a synthetic UI-test response.
        if fixture != nil || defaults.bool(forKey: "TestApp.cameraFixtureUsed") {
            defaults.removeObject(forKey: "optikosPrimeCameraInfo")
        }
        defaults.set(fixture != nil && fixture != "live", forKey: "TestApp.cameraFixtureUsed")
        #if targetEnvironment(simulator)
        let model = "iPhone17,2"
        if defaults.string(forKey: "TestApp.simulatorCameraModel") != model {
            defaults.removeObject(forKey: "optikosPrimeCameraInfo")
        }
        defaults.set(model, forKey: "TestApp.simulatorCameraModel")
        #else
        guard fixture != nil else { return }
        UserDefaults.standard.removeObject(forKey: "optikosPrimeCameraInfo")
        #endif
        // URLSession clients may use an explicit configuration that ignores global registration.
        // Replace only the default-configuration factory in this test process.
        let original = class_getClassMethod(URLSessionConfiguration.self, NSSelectorFromString("defaultSessionConfiguration"))!
        let replacement = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.optikosFixtureConfiguration))!
        method_exchangeImplementations(original, replacement)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path == "/sdk/v1/get-device-camera-settings"
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let mode = ProcessInfo.processInfo.environment["OPTIKOS_CAMERA_FIXTURE"]
        if mode == nil || mode == "live" {
            forwardToServer()
            return
        }
        Self.lock.lock()
        Self.requests += 1
        let number = Self.requests
        Self.lock.unlock()
        // Fail a duplicate request so the prefetch test also verifies cache reuse.
        if mode == "offline" || number > 1 {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let supported = mode != "unsupported"
        let data = Data("""
        {"supported":\(supported),"telephoto_usable":false,"camera_subject_distance_m":1.5,
         "first_flash_torch_strength":0.5,"iris_radius_target_px_min":20,"iris_radius_target_px_max":60}
        """.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    private func forwardToServer() {
        var forwarded = request
        #if targetEnvironment(simulator)
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        var items = components.queryItems ?? []
        items.removeAll { $0.name == "model" }
        items.append(URLQueryItem(name: "model", value: "iPhone17,2"))
        components.queryItems = items
        forwarded.url = components.url
        #endif
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = (configuration.protocolClasses ?? []).filter { $0 != CameraInfoTestProtocol.self }
        let session = URLSession(configuration: configuration)
        forwardingSession = session
        forwardingTask = session.dataTask(with: forwarded) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                self.client?.urlProtocol(self, didFailWithError: error)
            } else if let response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                if let data { self.client?.urlProtocol(self, didLoad: data) }
                self.client?.urlProtocolDidFinishLoading(self)
            }
            session.finishTasksAndInvalidate()
        }
        forwardingTask?.resume()
    }

    override func stopLoading() {
        forwardingTask?.cancel()
        forwardingSession?.invalidateAndCancel()
    }
}
private extension URLSessionConfiguration {
    @objc nonisolated class func optikosFixtureConfiguration() -> URLSessionConfiguration {
        let configuration = optikosFixtureConfiguration()
        configuration.protocolClasses = [CameraInfoTestProtocol.self] + (configuration.protocolClasses ?? [])
        return configuration
    }
}
#endif
