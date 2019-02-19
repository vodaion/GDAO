//
//  TestCoreDataStackAndModels.swift
//  GDAOTests
//
//  Created by IonVoda on 16/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import XCTest
import CoreData
@testable import GDAO

class TestCoreDataStackAndModels: XCTestCase {
    private var coreDataStack: CoreDataStack!

    override func setUp() {
        super.setUp()
        coreDataStack = CoreDataStack.init(modelName: "GDAO", persistentType: .inMemory)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        coreDataStack = nil
        super.tearDown()
    }
    
    func testCoreDataStackNotNil() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(coreDataStack)
    }

    func testCoreDataProfileExistInModel() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let profileTypeStr = String(describing: Profile.self)
        XCTAssertEqual(profileTypeStr, "Profile")

        let profileEntity = NSEntityDescription.entity(forEntityName: profileTypeStr, in: backgroudContext)
        XCTAssertNotNil(profileEntity)
        let profile = NSManagedObject.init(entity: profileEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(profile)

        let userRelationDescription = profile.entity.relationshipsByName["user"]
        XCTAssertNotNil(userRelationDescription)
        XCTAssertEqual(userRelationDescription!.isToMany, false)
    }

    func testCoreDataUserExistInModel() {
        let backgroudContext = coreDataStack.newBackgroundContext
        let userTypeStr = String(describing: User.self)
        XCTAssertEqual(userTypeStr, "User")

        let userEntity = NSEntityDescription.entity(forEntityName: userTypeStr, in: backgroudContext)
        XCTAssertNotNil(userEntity)
        let user = NSManagedObject.init(entity: userEntity!, insertInto: backgroudContext)
        XCTAssertNotNil(user)

        let profileRelationDescription = user.entity.relationshipsByName["profileSet"]
        XCTAssertNotNil(profileRelationDescription)
        XCTAssertEqual(profileRelationDescription!.isToMany, true)
    }
}
