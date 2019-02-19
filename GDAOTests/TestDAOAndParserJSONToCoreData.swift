//
//  TestParserJSONToCoreData.swift
//  GDAOTests
//
//  Created by IonVoda on 23/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import XCTest
import CoreData
import CwlPreconditionTesting

@testable import GDAO

class TestParserJSONToCoreData: XCTestCase {
    private var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack(modelName: "GDAO", persistentType: .inMemory)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        coreDataStack = nil
        super.tearDown()
    }

    private func loadJsonResult() -> Dictionary<String, NSObject> {
        return loadJsonResult(fileName: "UserWithProfile")
    }

    private func loadJsonResult2() -> Dictionary<String, NSObject> {
        return loadJsonResult(fileName: "UserWithProfile2")
    }

    private func loadJsonResult3() -> Dictionary<String, NSObject> {
        return loadJsonResult(fileName: "UserWithProfile3")
    }

    private func loadJsonResult(fileName: String) -> Dictionary<String, NSObject> {
        let bundle = Bundle(for: type(of: self))
        XCTAssertNotNil(bundle)

        let path = bundle.path(forResource: fileName, ofType: "json")
        XCTAssertNotNil(path)

        let urlPath = URL(fileURLWithPath: path!)
        XCTAssertNotNil(urlPath)

        let data = try? Data(contentsOf: urlPath, options: .mappedIfSafe)
        XCTAssertNotNil(data)

        let jsonResult = try? JSONSerialization.jsonObject(with: data!, options: .mutableLeaves)
        XCTAssertNotNil(jsonResult)

        let jsonResultDic = jsonResult as? Dictionary<String, NSObject>
        XCTAssertNotNil(jsonResultDic)

        return jsonResultDic!
    }

    func test_ParseSyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate)
        XCTAssertNotNil(parser)

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let typeFirst = type(of: users!.first!)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)
        } catch {
            XCTFail()
        }
    }

    func test_ParseAsyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {
                if modelType == Profile.self {
                    return ["id"]
                } else if modelType == User.self {
                    return ["id"]
                }
                return []
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate)
        XCTAssertNotNil(parser)

        let expect = expectation(description: "ExpectParserAsyncOperation")
        let jsonResult = loadJsonResult()

        var users: [Any]?
        parser.parseAsync([jsonResult], rootType: User.self) { value in
            users = value
            expect.fulfill()
        }
        wait(for: [expect], timeout: 3)
        
        XCTAssertNotNil(users)
        XCTAssertFalse(users!.isEmpty)
        XCTAssertTrue(users!.count == 1)
        let typeFirst = type(of: users!.first!)
        XCTAssertNotNil(typeFirst)
        XCTAssertTrue(typeFirst == User.self)

        let user = users!.first as! User
        XCTAssertTrue(user.profileSet?.count == 3)
    }

    func test_ParseSyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType_DefaultCleanup() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate, cleanupOption: .default)
        XCTAssertNotNil(parser)

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  3)
        } catch {
            XCTFail()
        }

        let jsonResult2 = loadJsonResult2()
        do {
            let users: [Any]? = try parser.parse([jsonResult2], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  7)
        } catch {
            XCTFail()
        }
    }

    func test_ParseSyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType_LightCleanup() {
        // This is an example of a performance test case.
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate, cleanupOption: .light)
        XCTAssertNotNil(parser)

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  3)
        } catch {
            XCTFail()
        }

        let jsonResult2 = loadJsonResult2()
        do {
            let users: [Any]? = try parser.parse([jsonResult2], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  5)
        } catch {
            XCTFail()
        }

        let jsonResult3 = loadJsonResult3()
        do {
            let users: [Any]? = try parser.parse([jsonResult3], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  5)
        } catch {
            XCTFail()
        }
    }

    func test_ParseSyncUser_parsedValue_AdvanceCleanup() {
        // This is an example of a performance test case.
        let coreDataStack = CoreDataStack(modelName: "GDAO", persistentType: .inSQLite)
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate, cleanupOption: .advance)
        XCTAssertNotNil(parser)

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  3)
        } catch {
            XCTFail()
        }

        let jsonResult2 = loadJsonResult2()
        do {
            let users: [Any]? = try parser.parse([jsonResult2], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  5)
        } catch {
            XCTFail()
        }
        do {
            let user = try dao.fetch(entityType: User.self)
            XCTAssertNotNil(user)

            let users1 = try dao.fetchAll(entityType: User.self)
            XCTAssertNotEqual(users1.count, 0)

            try dao.deleteAll(entityType: User.self, deleteUsingPersistentCoordinator: true)
            let users = try dao.fetchAll(entityType: User.self)
            XCTAssertEqual(users.count, 0)

            let profiles1 = try dao.fetchAll(entityType: Profile.self)
            XCTAssertNotEqual(profiles1.count, 0)
            try dao.deleteAll(entityType: Profile.self)
            let profiles = try dao.fetchAll(entityType: Profile.self)
            XCTAssertEqual(profiles.count, 0)
        } catch {
            XCTFail()
        }
    }

    func test_ParseSyncUserWithProfiles_parsed_Cleanup() {
        // This is an example of a performance test case.
        let coreDataStack = CoreDataStack(modelName: "GDAO", persistentType: .inSQLite)
        XCTAssertNotNil(coreDataStack)

        let privateContext = coreDataStack.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }
        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate, cleanupOption: .advance)
        XCTAssertNotNil(parser)
        
        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  3)
        } catch {
            XCTFail()
        }

        let jsonResult2 = loadJsonResult2()
        do {
            let users: [Any]? = try parser.parse([jsonResult2], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  5)
        } catch {
            XCTFail()
        }

        let jsonResult3 = loadJsonResult3()
        do {
            let users: [Any]? = try parser.parse([jsonResult3], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  5)
        } catch {
            XCTFail()
        }
        do {
            let user = try dao.fetch(entityType: User.self)
            XCTAssertNotNil(user)

            let users1 = try dao.fetchAll(entityType: User.self)
            XCTAssertNotEqual(users1.count, 0)

            try dao.deleteAll(entityType: User.self, deleteUsingPersistentCoordinator: true)
            let users = try dao.fetchAll(entityType: User.self)
            XCTAssertEqual(users.count, 0)

            let profiles1 = try dao.fetchAll(entityType: Profile.self)
            XCTAssertNotEqual(profiles1.count, 0)
            try dao.deleteAll(entityType: Profile.self)
            let profiles = try dao.fetchAll(entityType: Profile.self)
            XCTAssertEqual(profiles.count, 0)
        } catch {
            XCTFail()
        }
    }

    func test_ParseSyncUserWithProfiles_parsedValueIsArrayWithOneObjectUserType_DeleteAll() {
        // This is an example of a performance test case.
        let coreDataStack1 = CoreDataStack(modelName: "GDAO", persistentType: .inSQLite)
        XCTAssertNotNil(coreDataStack1)

        let privateContext = coreDataStack1.newBackgroundContext
        XCTAssertNotNil(privateContext)

        class DelegateParser: ParserDelegate {
            func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {

                switch modelType {
                case _ where modelType == Profile.self || modelType == User.self:
                    return ["id"]
                default:
                    return []
                }
            }
        }

        let dao = DAOCoreData(managedObjectContext: privateContext)
        XCTAssertNotNil(dao)
        let delegate = DelegateParser()
        XCTAssertNotNil(delegate)
        let parser = ParserJSONToCoreData.init(dao, delegate: delegate, cleanupOption: .default)
        XCTAssertNotNil(parser)

        let jsonResult = loadJsonResult()
        do {
            let users: [Any]? = try parser.parse([jsonResult], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  3)
        } catch {
            XCTFail()
        }

        let jsonResult2 = loadJsonResult2()
        do {
            let users: [Any]? = try parser.parse([jsonResult2], rootType: User.self)
            try privateContext.save()

            XCTAssertNotNil(users)
            XCTAssertFalse(users!.isEmpty)
            XCTAssertTrue(users!.count == 1)
            let firstObject = users!.first!

            let typeFirst = type(of: firstObject)
            XCTAssertNotNil(typeFirst)
            XCTAssertTrue(typeFirst == User.self)

            let firstObjectUser = firstObject as! User
            XCTAssertNotEqual(firstObjectUser.profileSet?.count, 0)
            XCTAssertEqual(firstObjectUser.profileSet?.count,  7)
        } catch {
            XCTFail()
        }
        do {
            let user = try dao.fetch(entityType: User.self)
            XCTAssertNotNil(user)

            let users1 = try dao.fetchAll(entityType: User.self)
            XCTAssertNotEqual(users1.count, 0)

            try dao.deleteAll(entityType: User.self, deleteUsingPersistentCoordinator: true)
            let users = try dao.fetchAll(entityType: User.self)
            XCTAssertEqual(users.count, 0)

            let profiles1 = try dao.fetchAll(entityType: Profile.self)
            XCTAssertNotEqual(profiles1.count, 0)
            try dao.deleteAll(entityType: Profile.self)
            let profiles = try dao.fetchAll(entityType: Profile.self)
            XCTAssertEqual(profiles.count, 0)
        } catch {
            XCTFail()
        }
    }
}
