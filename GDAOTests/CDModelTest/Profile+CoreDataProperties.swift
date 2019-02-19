//
//  Profile+CoreDataProperties.swift
//  GDAOTests
//
//  Created by IonVoda on 17/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var id: Int64
    @NSManaged public var name: String?
    @NSManaged public var type: Int16
    @NSManaged public var user: User?

}
