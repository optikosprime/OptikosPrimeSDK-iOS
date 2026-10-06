import XCTest

final class TestAppUITests: XCTestCase {
    @MainActor func testLaunchShowsFullFlowEntryPoint() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start full vision check"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Ready to start a vision check."].exists)
    }
}
