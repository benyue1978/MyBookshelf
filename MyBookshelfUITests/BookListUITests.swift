import XCTest

class BookListUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testAddBook() throws {
        // 清除所有数据以确保测试的独立性
        clearAllData()
        
        // 点击"Add Book"按钮
        app.buttons["Add Book"].tap()
        
        // 在 BookView 中填写书籍信息
        let titleTextField = app.textFields["Title"]
        titleTextField.tap()
        titleTextField.typeText("Test Book")
        
        let authorTextField = app.textFields["Author"]
        authorTextField.tap()
        authorTextField.typeText("Test Author")
        
        // 保存书籍
        app.buttons["Save"].tap()
        
        // 验证书籍是否出现在 ContentView 的书籍列表中
        XCTAssertTrue(app.staticTexts["Test Book"].exists, "Added book should appear in the book list")
    }
    
    private func clearAllData() {
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["Clear All Data"].tap()
        app.alerts["Confirm"].buttons["Clear"].tap()
        app.buttons["Done"].tap()
    }
}
