import Foundation
import OptikosPrimeSDK
import Testing

struct TestAppTests {
    @Test @MainActor func publishedSDKInitializesAndEvaluatesAllQuestionnaireAnswers() throws {
        let license = try #require(Bundle.main.object(forInfoDictionaryKey: "SDKLicenseKey") as? String)
        try OptikosPrimeSDK.initialize(licenseKey: license, environment: .production)
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
