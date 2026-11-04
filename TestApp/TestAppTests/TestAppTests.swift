import Foundation
import OptikosPrimeSDK
import Testing
@testable import TestApp

struct TestAppTests {
    @Test @MainActor func publishedSDKInitializesAndEvaluatesAllQuestionnaireAnswers() throws {
        let configuration = try SampleSDKConfiguration.load()
        try OptikosPrimeSDK.initialize(licenseKey: configuration.licenseKey, environment: configuration.environment)
        #expect(OptikosPrimeSDK.isInitialized)

        // VisionCheck's expected assessments: no symptoms young/older, symptoms young/older.
        let cases: [(Bool, Bool, [OptikosPrimeQuestionResult])] = [
            (true, true, [.normal, .normal, .hyperopia, .astigmatism]),
            (false, true, [.myopia, .myopia, .myopia, .myopia]),
            (false, false, [.astigmatism, .astigmatism, .astigmatism, .astigmatism]),
            (true, false, [.hyperopia, .presbyopia, .hyperopia, .presbyopia])
        ]
        for (canSeeFar, canSeeNear, expected) in cases {
            for hasHeadache in [false, true] {
                for hasEyeStrain in [false, true] {
                    for isOlderThan43 in [false, true] {
                        let answers = OptikosPrimeQuestionAnswers(hasHeadache: hasHeadache,
                            hasEyeStrain: hasEyeStrain, canSeeFar: canSeeFar,
                            canSeeNear: canSeeNear, isOlderThan43: isOlderThan43)
                        let index = (hasHeadache || hasEyeStrain ? 2 : 0) + (isOlderThan43 ? 1 : 0)
                        #expect(try OptikosPrimeQuestionEvaluator.evaluate(answers) == expected[index])
                    }
                }
            }
        }
    }

    @Test @MainActor func bundledLicensesInitializeTheirMatchingEnvironments() throws {
        defer { OptikosPrimeSDK.reset() }
        for (name, environment, licenseSetting) in [
            ("development", OptikosPrimeEnvironment.development, "SDKDevelopmentLicenseKey"),
            ("production", OptikosPrimeEnvironment.production, "SDKProductionLicenseKey")
        ] {
            var settings = Bundle.main.infoDictionary ?? [:]
            settings["SDKEnvironment"] = name
            let configuration = try SampleSDKConfiguration.load(from: settings)
            let matchesBundledLicense = configuration.licenseKey == settings[licenseSetting] as? String
            #expect(configuration.environment == environment)
            #expect(matchesBundledLicense)
            try OptikosPrimeSDK.initialize(licenseKey: configuration.licenseKey, environment: configuration.environment)
            #expect(OptikosPrimeSDK.isInitialized)
        }
    }

    @Test @MainActor func invalidEnvironmentOrMissingLicenseDoesNotFallBack() {
        let invalidSettings: [[String: Any]] = [
            ["SDKProductionLicenseKey": "production-license"],
            ["SDKEnvironment": "invalid", "SDKProductionLicenseKey": "production-license"],
            ["SDKEnvironment": "development", "SDKProductionLicenseKey": "production-license"],
            ["SDKEnvironment": "production", "SDKDevelopmentLicenseKey": "development-license"],
            ["SDKEnvironment": "development", "SDKDevelopmentLicenseKey": " \n"]
        ]
        for settings in invalidSettings {
            #expect(throws: (any Error).self) {
                try SampleSDKConfiguration.load(from: settings)
            }
        }
    }

    @Test func publishedResultExportsStableJSON() throws {
        let eye = OptikosPrimeEyeResult(hyperopia: 0, myopia: 0, astigmatism: 0, inconclusive: 0,
                                        normal: 1, unmeasurableRangeMinimum: nil, unmeasurableRangeMaximum: nil)
        let result = OptikosPrimeResult(measurementID: "test-measurement", leftEye: eye, rightEye: eye,
                                       left: [.init(type: .normal)], right: [.init(type: .normal)],
                                       questionnaire: .presbyopia)
        let data = try result.jsonData()
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["conclusion"] == nil)
        for key in ["left", "right", "results"] {
            #expect(json[key] as? [[String: String]] == [["type": "presbyopia"]])
        }
        #expect(json["questionnaire"] as? String == "presbyopia")
        #expect(json["measurementID"] as? String == "test-measurement")
        #expect(try JSONDecoder().decode(OptikosPrimeResult.self, from: data) == result)
    }

    @Test @MainActor func publishedErrorsUseDocumentedDomainAndCode() {
        let error = OptikosPrimeError.deviceNotSupported as NSError
        #expect(error.domain == OptikosPrimeSDKBridge.errorDomain)
        #expect(error.domain == "com.optikosprime.sdk")
        #expect(error.code == OptikosPrimeErrorCode.deviceNotSupported.rawValue)
        #expect(error.code == 1003)
    }
}
