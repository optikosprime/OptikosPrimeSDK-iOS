import Foundation
import OptikosPrimeSDK
import Testing

struct TestAppTests {
    @Test func publishedResultExportsStableJSON() throws {
        let eye = OptikosPrimeEyeResult(hyperopia: 0, myopia: 0, astigmatism: 0, inconclusive: 0,
                                        normal: 1, unmeasurableRangeMinimum: nil, unmeasurableRangeMaximum: nil)
        let result = OptikosPrimeResult(measurementID: "test-measurement", leftEye: eye, rightEye: eye,
                                       conclusion: .finding, questionnaire: .presbyopia)
        let data = try result.jsonData()
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["conclusion"] as? String == "finding")
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
