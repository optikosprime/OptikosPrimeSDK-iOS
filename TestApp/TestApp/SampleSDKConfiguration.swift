import Foundation
import OptikosPrimeSDK

struct SampleSDKConfiguration {
    let environment: OptikosPrimeEnvironment
    let licenseKey: String

    static func load(from info: [String: Any] = Bundle.main.infoDictionary ?? [:]) throws -> Self {
        let environment: OptikosPrimeEnvironment
        let licenseSetting: String
        switch info["SDKEnvironment"] as? String {
        case "development":
            environment = .development
            licenseSetting = "SDKDevelopmentLicenseKey"
        case "production":
            environment = .production
            licenseSetting = "SDKProductionLicenseKey"
        default:
            throw ConfigurationError("Set SDKEnvironment in Info.plist to development or production.")
        }
        guard let license = info[licenseSetting] as? String,
              !license.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError("Set \(licenseSetting) in Info.plist to a matching license for this app's bundle identifier.")
        }
        return Self(environment: environment, licenseKey: license)
    }

    private struct ConfigurationError: LocalizedError {
        let errorDescription: String?

        init(_ description: String) {
            errorDescription = description
        }
    }
}
