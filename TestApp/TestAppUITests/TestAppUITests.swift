import XCTest

final class TestAppUITests: XCTestCase {
    @MainActor
    func testFullFlowStartsAndCancels() throws {
        try checkFullFlow(useObjectiveC: false)
    }

    @MainActor
    func testObjectiveCFullFlowStartsAndCancels() throws {
        try checkFullFlow(useObjectiveC: true)
    }

    @MainActor
    private func checkFullFlow(useObjectiveC: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()

        let startButton = app.buttons["Start full vision check"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 10))
        if useObjectiveC {
            app.segmentedControls.buttons["Objective-C"].tap()
        }
        startButton.tap()

        XCTAssertTrue(app.staticTexts["Ask a friend to take your picture."].waitForExistence(timeout: 10))
        // The SDK exposes an icon-only close button beside Continue.
        app.buttons.matching(NSPredicate(format: "label != %@", "Continue")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["The test was cancelled."].waitForExistence(timeout: 5))
        XCTAssertTrue(startButton.isHittable)
    }
}
