import XCTest
@testable import MyBookshelf

class ShelfListViewUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // 设置启动参数，表明这是一个 UI 测试
        app.launchArguments.append("--uitesting")
        
        app.launch()

        clearCoreData()
    }

    func testAddShelf() throws {
        let newShelfName = "Test Shelf"
        // 打开 ShelfListView
        app.buttons["Shelves"].tap()
        
        // 添加新书架
        app.textFields["Add Shelf"].tap()
        app.textFields["Add Shelf"].typeText(newShelfName)
        app.buttons["plus.circle.fill"].tap()
        
        // 验证新书架是否出现在列表中
        XCTAssertTrue(app.staticTexts[newShelfName].exists)
        
        // 返回 ContentView 并验证新书架是否出现
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts[newShelfName].exists)
        
        // 打开 BookView 并验证新书架是否出现在选择列表中
        app.buttons["Add Book"].tap()
        app.descendants(matching: .any)["ShelfPicker"].firstMatch.tap()
        XCTAssertTrue(app.buttons[newShelfName].exists)
    }

    func testUpdateShelf() throws {
        let originalShelfName = "Original Shelf"
        let updatedShelfName = "Updated Shelf"
        
        addShelf(name: originalShelfName)
        
        // 打开 ShelfListView
        app.buttons["Shelves"].tap()
        
        // 双击书架进入编辑模式
        let shelfToEdit = app.staticTexts[originalShelfName].firstMatch
        shelfToEdit.doubleTap()
        
        // 更新书架名称
        let textField = app.textFields["Shelf Name"]
        textField.clearAndEnterText(updatedShelfName)
        app.buttons["checkmark.circle.fill"].tap()
        
        // 验证更新后的书架名称是否出现在列表中
        XCTAssertTrue(app.staticTexts[updatedShelfName].exists)
        
        // 返回 ContentView 并验证更新后的书架名称是否出现
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts[updatedShelfName].exists)
        
        // 打开 BookView 并验证更新后的书架名称是否出现在选择列表中
        app.buttons["Add Book"].tap()
        app.descendants(matching: .any)["ShelfPicker"].firstMatch.tap()
        XCTAssertTrue(app.buttons[updatedShelfName].exists)
    }

    func testDeleteShelf() throws {
        let shelfToDelete = "Shelf to Delete"
        
        addShelf(name: shelfToDelete)
        
        // 打开 ShelfListView
        app.buttons["Shelves"].tap()
        
        // 删除书架
        app.staticTexts[shelfToDelete].firstMatch.swipeLeft()
        app.buttons["Delete"].tap()
        
        // 验证书架是否已从列表中删除
        XCTAssertFalse(app.staticTexts[shelfToDelete].exists)
        
        // 返回 ContentView 并验证书架是否已删除
        app.buttons["Back"].tap()
        XCTAssertFalse(app.staticTexts[shelfToDelete].exists)
        
        // 打开 BookView 并验证已删除的书架是否不再出现在选择列表中
        app.buttons["Add Book"].tap()
        app.descendants(matching: .any)["ShelfPicker"].firstMatch.tap()
        XCTAssertFalse(app.buttons[shelfToDelete].exists)
    }

    func testClearAllData() throws {
        // 添加一个新书架
        let newShelfName = "Test Shelf for Clearing"
        addShelf(name: newShelfName)
        
        // 验证新书架是否被添加
        XCTAssertTrue(app.staticTexts[newShelfName].exists, "New shelf should exist before clearing data")
        
        // 清除所有数据
        clearCoreData()
        
        // 验证书架已经从 ContentView 删除
        XCTAssertFalse(app.staticTexts[newShelfName].exists, "Shelf should not exist after clearing data")
        
        // 验证书架列表是否为空
        app.buttons["Shelves"].tap() // 打开书架列表视图
        
        // 等待一段时间以确保视图已更新
        let emptyListIndicator = app.textFields["Add Shelf"]
        XCTAssertTrue(emptyListIndicator.waitForExistence(timeout: 5), "Empty list indicator should appear after clearing data")
        
        // 验证之前添加的书架不再存在
        XCTAssertFalse(app.staticTexts[newShelfName].exists, "Shelf should not exist after clearing data")
        
        app.buttons["Back"].tap()
        
        app.buttons["Add Book"].tap()
        app.descendants(matching: .any)["ShelfPicker"].firstMatch.tap()
        XCTAssertFalse(app.buttons[newShelfName].exists)
    }

    // 辅助方法：添加书架
    private func addShelf(name: String) {
        // 打开 ShelfListView
        app.buttons["Shelves"].tap()
        
        // 添加新书架
        app.textFields["Add Shelf"].tap()
        app.textFields["Add Shelf"].typeText(name)
        app.buttons["plus.circle.fill"].tap()
        
        // 返回 ContentView
        app.buttons["Back"].tap()
    }

    private func clearCoreData() {
        // 打开设置视图
        app.buttons["gear"].tap()
        
        // 点击清除数据按钮
        app.buttons["Clear All Data"].tap()
        
        // 确认清除操作
        app.alerts["Confirm"].buttons["Clear"].tap()
        
        // 等待清除操作完成
        let exp = expectation(description: "Clear Core Data")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        
        // 返回主视图
        app.buttons["Done"].tap()
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        self.tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
