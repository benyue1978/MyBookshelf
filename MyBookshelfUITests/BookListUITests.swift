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
        let titleTextField = app.textFields["BookTitleField"]
        titleTextField.tap()
        titleTextField.typeText("Test Book")
        
        let authorTextField = app.textFields["BookAuthorField"]
        authorTextField.tap()
        authorTextField.typeText("Test Author")
        
        let publisherTextField = app.textFields["BookPublisherField"]
        publisherTextField.tap()
        publisherTextField.typeText("Test Publisher")
        
        let publishDateTextField = app.textFields["BookPublishDateField"]
        publishDateTextField.tap()
        publishDateTextField.typeText("2024-01-01")
        
        let isbn13TextField = app.textFields["BookISBN13Field"]
        isbn13TextField.tap()
        isbn13TextField.typeText("1234567890123")
        
        let isbn10TextField = app.textFields["BookISBN10Field"]
        isbn10TextField.tap()
        isbn10TextField.typeText("1234567890")
        
        // 保存书籍
        app.buttons["Save"].tap()
        
        // 验证书籍是否出现在 ContentView 的书籍列表中
        XCTAssertTrue(app.staticTexts["Test Book"].exists, "Added book should appear in the book list")
    }
    
    func testSearchFunctionality() throws {
        // 清除所有数据并添加测试书籍
        clearAllData()
        addTestBooks()
        
        // 获取搜索栏
        let searchField = app.textFields["SearchBarTextField"]
        
        // 测试搜索存在的书籍
        searchField.tap()
        searchField.typeText("Swift")
        
        // 验证搜索结果
        XCTAssertTrue(app.staticTexts["Swift Programming"].exists, "Swift Programming should be in the search results")
        XCTAssertFalse(app.staticTexts["Python Basics"].exists, "Python Basics should not be in the search results")
        
        // 清除搜索栏
        app.buttons["ClearSearchButton"].tap()
        
        // 测试搜索不存在的书籍
        searchField.typeText("Java")
        
        // 验证搜索结果为空
        XCTAssertTrue(app.staticTexts["No Books"].exists, "No books should be found for 'Java'")
        
        // 清除搜索栏
        app.buttons["ClearSearchButton"].tap()
        
        // 验证所有书籍重新出现
        XCTAssertTrue(app.staticTexts["Swift Programming"].exists, "Swift Programming should reappear after clearing search")
        XCTAssertTrue(app.staticTexts["Python Basics"].exists, "Python Basics should reappear after clearing search")
    }
    
    private func clearAllData() {
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["Clear All Data"].tap()
        app.alerts["Confirm"].buttons["Clear"].tap()
        app.buttons["Done"].tap()
    }
    
    private func addTestBooks() {
        // 添加第一本测试书籍
        app.buttons["Add Book"].tap()
        app.textFields["BookTitleField"].tap()
        app.textFields["BookTitleField"].typeText("Swift Programming")
        app.textFields["BookAuthorField"].tap()
        app.textFields["BookAuthorField"].typeText("John Doe")
        app.buttons["Save"].tap()
        
        // 添加第二本测试书籍
        app.buttons["Add Book"].tap()
        app.textFields["BookTitleField"].tap()
        app.textFields["BookTitleField"].typeText("Python Basics")
        app.textFields["BookAuthorField"].tap()
        app.textFields["BookAuthorField"].typeText("Jane Smith")
        app.buttons["Save"].tap()
    }
}
