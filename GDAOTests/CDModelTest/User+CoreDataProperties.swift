//
//  User+CoreDataProperties.swift
//  GDAOTests
//
//  Created by IonVoda on 17/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var email: String?
    @NSManaged public var profileSet: NSSet?

}

// MARK: Generated accessors for profileSet
extension User {

    @objc(addProfileSetObject:)
    @NSManaged public func addToProfileSet(_ value: Profile)

    @objc(removeProfileSetObject:)
    @NSManaged public func removeFromProfileSet(_ value: Profile)

    @objc(addProfileSet:)
    @NSManaged public func addToProfileSet(_ values: NSSet)

    @objc(removeProfileSet:)
    @NSManaged public func removeFromProfileSet(_ values: NSSet)

}
