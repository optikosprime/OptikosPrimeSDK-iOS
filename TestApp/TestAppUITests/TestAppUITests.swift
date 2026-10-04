import XCTest

final class TestAppUITests: XCTestCase {
    @MainActor func testSwiftFullFlowStartsAndCancels() throws { checkFullFlow(useObjectiveC: false) }
    @MainActor func testObjectiveCFullFlowStartsAndCancels() throws { checkFullFlow(useObjectiveC: true) }
    @MainActor func testSwiftPrefetchIsReusedByFlow() throws { checkFullFlow(useObjectiveC: false, prefetch: true) }
    @MainActor func testObjectiveCPrefetchIsReusedByFlow() throws { checkFullFlow(useObjectiveC: true, prefetch: true) }
    @MainActor func testSwiftUnsupportedDeviceReturnsTypedFailure() { checkUnsupported(useObjectiveC: false) }
    @MainActor func testObjectiveCUnsupportedDeviceReturnsTypedFailure() { checkUnsupported(useObjectiveC: true) }

    // Opt-in live check, separate from deterministic UI tests.
    @MainActor func testLiveCameraSupportForSimulatorModel() throws {
        guard ProcessInfo.processInfo.environment["OPTIKOS_RUN_LIVE_CAMERA_TEST"] == "1" else {
            throw XCTSkip("Set OPTIKOS_RUN_LIVE_CAMERA_TEST=1 to check the production service.")
        }
        let app = launch(useObjectiveC: false, fixture: "live")
        app.buttons["Check camera support"].tap()
        XCTAssertTrue(app.staticTexts["Camera is supported."].waitForExistence(timeout: 30), app.debugDescription)
        app.buttons["Start full vision check"].tap()
        XCTAssertTrue(app.staticTexts["Ask a friend to take your picture."].waitForExistence(timeout: 10), app.debugDescription)
        app.buttons.matching(NSPredicate(format: "label != %@", "Continue")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["The test was cancelled."].waitForExistence(timeout: 5))
    }

    @MainActor private func launch(useObjectiveC: Bool, fixture: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["OPTIKOS_CAMERA_FIXTURE"] = fixture
        app.launch()
        XCTAssertTrue(app.buttons["Start full vision check"].waitForExistence(timeout: 10), app.debugDescription)
        if useObjectiveC { app.segmentedControls.buttons["Objective-C"].tap() }
        return app
    }

    @MainActor private func checkFullFlow(useObjectiveC: Bool, prefetch: Bool = false) {
        let app = launch(useObjectiveC: useObjectiveC, fixture: "supported")
        if prefetch {
            app.buttons["Check camera support"].tap()
            XCTAssertTrue(app.staticTexts["Camera is supported."].waitForExistence(timeout: 10), app.debugDescription)
        }
        let startButton = app.buttons["Start full vision check"]
        startButton.tap()
        XCTAssertTrue(app.staticTexts["Ask a friend to take your picture."].waitForExistence(timeout: 10), app.debugDescription)
        app.buttons.matching(NSPredicate(format: "label != %@", "Continue")).firstMatch.tap()
        XCTAssertTrue(app.staticTexts["The test was cancelled."].waitForExistence(timeout: 5))
        XCTAssertTrue(startButton.isHittable)
    }

    @MainActor private func checkUnsupported(useObjectiveC: Bool) {
        let app = launch(useObjectiveC: useObjectiveC, fixture: "unsupported")
        app.buttons["Start full vision check"].tap()
        XCTAssertTrue(app.staticTexts["This device is not supported."].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertFalse(app.staticTexts["Ask a friend to take your picture."].exists)
        XCTAssertTrue(app.buttons["Start full vision check"].isHittable)
    }
}
