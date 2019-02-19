//
//  GDAOBase.swift
//  GDAOBase
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

enum DAOError<T: NSManagedObject>: Error {
    typealias C =  NSFetchRequestResult
    case castFail(requester: [C], requestedType: T.Type)
    case missingUniqueIDs(classType: T.Type)
}

class DAOCoreData {
    private let managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    func perform(_ completion: @escaping () ->Void) {
        managedObjectContext.perform {
            completion()
        }
    }

    func fetch<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil) throws -> C? {
        let objects = try fetchAll(entityType: entityType, predicate: predicate, sorts: sorts, fetchLimit: 1)
        return objects.first
    }

    func fetchAll<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, sorts: [NSSortDescriptor]? = nil, batchSize: Int? = nil, fetchLimit: Int? = nil) throws -> [C] {
        let typeStr = String(describing: entityType)
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: typeStr)

        fetchRequest.sortDescriptors = sorts ?? []
        if let batchSize = batchSize {
            fetchRequest.fetchBatchSize = batchSize
        }

        if let fetchLimit = fetchLimit {
            fetchRequest.fetchLimit = fetchLimit
        }

        fetchRequest.predicate = predicate
        let results: [NSFetchRequestResult] = try managedObjectContext.fetch(fetchRequest)
        guard let objects: [C] = results as? [C] else {
            throw DAOError.castFail(requester: results, requestedType: entityType)
        }
        return objects
    }

    // uniqueIdentifiers: (key, val) pair to identify uniquelly an object
    func fetch<C: NSManagedObject>(entityType: C.Type, uniqueIdentifiers: [String: NSObject]) throws -> C? {
        let allObjects = try fetchAll(entityType: entityType, uniqueIdentifiers: uniqueIdentifiers, fetchLimit: 1)
        return allObjects.first
    }

    func fetchAll<C: NSManagedObject>(entityType: C.Type, uniqueIdentifiers: [String: NSObject], sorts: [NSSortDescriptor]? = nil, batchSize: Int? = nil, fetchLimit: Int? = nil) throws -> [C] {
        guard uniqueIdentifiers.isEmpty == false else {
            throw DAOError.missingUniqueIDs(classType: entityType)
        }

        let predicateArray: [NSPredicate] = uniqueIdentifiers.compactMap() { (key, value) in
            let pred = NSPredicate(format: "%K == %@", key, value)
            return pred
        }

        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
        let allObjects = try fetchAll(entityType: entityType, predicate: predicate, sorts: sorts, batchSize: batchSize, fetchLimit: fetchLimit)
        return allObjects
    }

    // CREATE
    func insert<C: NSManagedObject>(entityType: C.Type) throws -> C {
        let typeStr = String(describing: entityType)
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: typeStr, into: managedObjectContext)

        guard let managedObjectC = managedObject as? C else {
            throw DAOError.castFail(requester: [managedObject], requestedType: entityType)
        }

        return managedObjectC
    }

    //DELETE
    func delete<C: NSManagedObject>(_ managedObject: C) {
        managedObjectContext.delete(managedObject)
    }

    func deleteObject(with objectID: NSManagedObjectID) {
        let object = managedObjectContext.object(with: objectID)
        self.delete(object)
    }

    func deleteAll<C: NSManagedObject>(entityType: C.Type, predicate: NSPredicate? = nil, deleteUsingPersistentCoordinator: Bool = false) throws -> Void {
        let typeStr = String(describing: entityType)

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: typeStr)
        fetchRequest.includesPropertyValues = false

        if let predicate = predicate {
            fetchRequest.predicate = predicate
        }
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result: NSBatchDeleteResult?
        if deleteUsingPersistentCoordinator {
            result = try managedObjectContext.persistentStoreCoordinator?.execute(deleteRequest, with: managedObjectContext) as? NSBatchDeleteResult
        } else {
            result = try managedObjectContext.execute(deleteRequest) as? NSBatchDeleteResult
        }
        if let objectIDArray = result?.result as? [NSManagedObjectID], objectIDArray.isEmpty == false {
            let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedObjectContext])
        }
    }
}
