//
//  NSManagedObject+Ext.swift
//  GDAO
//
//  Created by IonVoda on 21/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    func classType(relationshipName: String) -> NSManagedObject.Type {
        let modelEntity = self.entity
        let modelAttributes = modelEntity.relationshipsByName
        let entityDescription = modelAttributes[relationshipName]
        guard
            let relationClassStr = entityDescription?.destinationEntity?.managedObjectClassName,
            let classType = NSClassFromString(relationClassStr) as? NSManagedObject.Type else {
                fatalError("Missing relationshipName:\(relationshipName) in NSManagedObjectEntity:\(modelEntity)")
        }

        return classType
    }

    func isToMany(relationshipName: String) -> Bool {
        let modelEntity = self.entity
        let modelAttributes = modelEntity.relationshipsByName
        let entityDescription = modelAttributes[relationshipName]
        let isToMany = entityDescription?.isToMany ?? false
        return isToMany
    }
}

