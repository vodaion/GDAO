//
//  ParserJSONToCoreData.swift
//  GDAOBase
//
//  Created by IonVoda on 12/08/2018.
//  Copyright © 2018 IonVoda. All rights reserved.
//

import Foundation
import CoreData

enum ParserJSONToCoreDataError: Error {
    case missingDelegate
    case missingIds(modelType: NSManagedObject.Type)
    case failCreateRellation(className: String, inParent: NSManagedObject)
    case unknowDataTypeForRellation(className: String, inParent: NSManagedObject)
}

protocol ParserDelegate: class {
    func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String>
    func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String
    func adjust(propertyValue: NSObject, propertyName: String, for model: NSManagedObject) -> NSObject?
}

extension ParserDelegate {
    func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String {
        return propertyName
    }

    func adjust(propertyValue: NSObject, propertyName: String, for model: NSManagedObject) -> NSObject? {
        return propertyValue
    }
}


class CleanupOption {
    static let `default`: CleanupOption = CleanupOption()
    static let light: CleanupOption = LightCleanupOption()
    static let advance: CleanupOption = AdvanceCleanupOption()

    fileprivate func validate(objectID: NSManagedObjectID) {}
    fileprivate func markToCleanup(local oldRelation: Set<NSManagedObject>, parsed newRelation: Set<NSManagedObject>, relationshipName: String, inParent: NSManagedObject) {}
    fileprivate func cleanupObjectsHangingInTheAir(in dao: DAOCoreData) {}
}

fileprivate class LightCleanupOption: CleanupOption {
    fileprivate var cleanupObjectIDSet = Set<NSManagedObjectID>()
    fileprivate override func validate(objectID: NSManagedObjectID) {
        cleanupObjectIDSet.remove(objectID)
    }

    fileprivate override func markToCleanup(local oldRelation: Set<NSManagedObject>, parsed newRelation: Set<NSManagedObject>, relationshipName: String, inParent: NSManagedObject) {
        let subtracted = oldRelation
            .subtracting(newRelation)

        let objectIDs = subtracted
            .compactMap { $0.objectID }

        let newCleanupObjectIDSet = cleanupObjectIDSet
            .subtracting(newRelation.compactMap { $0.objectID })

        cleanupObjectIDSet = newCleanupObjectIDSet.union(objectIDs)
    }

    fileprivate override func cleanupObjectsHangingInTheAir(in dao: DAOCoreData) {
        cleanupObjectIDSet.forEach() { objectID in
            dao.deleteObject(with: objectID)
        }
    }
}

fileprivate class AdvanceCleanupOption: LightCleanupOption {
    fileprivate override func markToCleanup(local oldRelation: Set<NSManagedObject>, parsed newRelation: Set<NSManagedObject>, relationshipName: String, inParent: NSManagedObject) {
        let subtracted = oldRelation
            .subtracting(newRelation)

        let parentEntityDescription = inParent.entity
        let parentObjectID = inParent.objectID

        let objectIDs: [NSManagedObjectID] = subtracted
            .compactMap { object in object
                    .entity
                    .relationships(forDestination: parentEntityDescription)
                    .compactMap { $0.inverseRelationship?.name == relationshipName ? $0.inverseRelationship?.inverseRelationship : nil }
                    .compactMap { relation in object
                        .objectIDs(forRelationshipNamed: relation.name)
                        .drop { $0 == parentObjectID }
                        .isEmpty ? object.objectID : nil
                    }
            }.flatMap { $0 }

        let newCleanupObjectIDSet = cleanupObjectIDSet
            .subtracting(newRelation.compactMap { $0.objectID })

        cleanupObjectIDSet = newCleanupObjectIDSet.union(objectIDs)
    }
}

final class ParserJSONToCoreData {
    private class ParserJSONToCoreDataDelegate: ParserDelegate {
        private weak var delegate: ParserDelegate?

        init(delegate: ParserDelegate?) {
            self.delegate = delegate
        }

        func findPrimaryKeys(for modelType: NSManagedObject.Type) throws -> Set<String> {
            guard let ids = try delegate?.findPrimaryKeys(for: modelType) else {
                throw ParserJSONToCoreDataError.missingDelegate
            }

            guard ids.isEmpty == false else {
                throw ParserJSONToCoreDataError.missingIds(modelType: modelType)
            }
            return ids
        }

        func adjust(propertyName: String, for modelType: NSManagedObject.Type) -> String {
            guard let adjustedCoreDataPropertyName = delegate?.adjust(propertyName: propertyName, for: modelType) else {
                return propertyName
            }
            return adjustedCoreDataPropertyName
        }

        func adjust(propertyValue: NSObject, propertyName: String, for model: NSManagedObject) -> NSObject? {
            guard let adjustedPropertyValue = delegate?.adjust(propertyValue: propertyValue, propertyName: propertyName, for: model) else {
                return propertyValue
            }
            return adjustedPropertyValue
        }
    }

    //MARK: Properties
    private let cleanupOption: CleanupOption

    private let daoBase: DAOCoreData
    private let delegate: ParserJSONToCoreDataDelegate

    //MARK: Initializer
    init(_ dao: DAOCoreData, delegate: ParserDelegate?, cleanupOption: CleanupOption = CleanupOption.default) {
        self.daoBase = dao
        self.delegate = ParserJSONToCoreDataDelegate(delegate: delegate)
        self.cleanupOption = cleanupOption
    }

    //MARK: - Public methods
    func parse<C: NSManagedObject>(_ array: [[String: NSObject]], rootType: C.Type) throws -> [C] {
        let parsedManagedObjects = try addEntityArray(array, modelType: rootType)
        cleanupObjectsHangingInTheAir()
        return parsedManagedObjects
    }

    func parseAsync<C: NSManagedObject>(_ array: [[String: NSObject]], rootType: C.Type, completion: @escaping ([C]?) -> Void) {
        daoBase.perform { [weak self] in
            let parsedManagedObjects: [C]?
            do {
                parsedManagedObjects = try self?.parse(array, rootType: rootType)
                self?.cleanupObjectsHangingInTheAir()
            } catch {
                parsedManagedObjects = nil
            }
            completion(parsedManagedObjects)
        }
    }

    // MARK: - Private/Fileprivate methods
    // MARK: Cleanup
    private func cleanupObjectsHangingInTheAir() {
        cleanupOption.cleanupObjectsHangingInTheAir(in: daoBase)
    }
    // MARK: AddEntity methods
    private func addEntityArray<C: NSManagedObject>(_ entities: [[String: NSObject]], modelType: C.Type) throws -> [C] {
        let cdArray: [C] = try entities.compactMap { entity in
            let childObj = try addEntity(entity, modelType: modelType)
            return childObj
        }
        return cdArray
    }

    private func addEntity<C: NSManagedObject>(_ jsonEntity: [String: NSObject], modelType: C.Type) throws -> C? {
        guard jsonEntity.isEmpty == false else {
            return nil
        }

        let identifiers = try delegate.findPrimaryKeys(for: modelType)
        let identifiersDic = identifiers.reduce([String: NSObject]()) { (result, jsonPropertyName) in
            let coreDataPropertyName: String = delegate.adjust(propertyName: jsonPropertyName, for: modelType)
            
            var resultDic = result
            resultDic[coreDataPropertyName] = jsonEntity[jsonPropertyName]
            return resultDic
        }

        let model: C
        if let fetchedModel = try daoBase.fetch(entityType: modelType, uniqueIdentifiers: identifiersDic) {
            model = fetchedModel
        } else {
            model = try daoBase.insert(entityType: modelType)
        }


        let allPropertiesKeySet: Set<String> = Set(model.entity.propertiesByName.keys)
        let relationshipsKeySet: Set<String> = Set(model.entity.relationshipsByName.keys)
        let propertiesKeySet: Set<String> = allPropertiesKeySet.subtracting(relationshipsKeySet)
        cleanupOption.validate(objectID: model.objectID)

        try jsonEntity.forEach{ (jsonPropertyName, value) in
            let adjustedPropertyNameToCoreData = delegate.adjust(propertyName: jsonPropertyName, for: modelType)
            if relationshipsKeySet.contains(adjustedPropertyNameToCoreData) {
                let relationValue = try createRelation(propertyValue: value, relationshipName: adjustedPropertyNameToCoreData, parent: model)
                model.setValue(relationValue, forKey: adjustedPropertyNameToCoreData)
            } else if propertiesKeySet.contains(adjustedPropertyNameToCoreData) {
                let propertyValue = delegate.adjust(propertyValue: value, propertyName: adjustedPropertyNameToCoreData, for: model)
                model.setValue(propertyValue, forKey: adjustedPropertyNameToCoreData)
            }
        }
        return model
    }

    private func createRelation<C: NSManagedObject>(propertyValue: NSObject, relationshipName: String, parent: C) throws -> NSObject? {
        if let objectToProcess = propertyValue as? [String: NSObject] {
            if parent.isToMany(relationshipName: relationshipName) {
                let entities = try union(value: [objectToProcess], relationshipName: relationshipName, parent: parent)
                return entities
            } else {
                let type = parent.classType(relationshipName: relationshipName)
                let entity = try addEntity(objectToProcess, modelType: type)
                return entity
            }
        } else if let objectToProcess = propertyValue as? [[String: NSObject]] {
            if parent.isToMany(relationshipName: relationshipName) {
                let entities = try union(value: objectToProcess, relationshipName: relationshipName, parent: parent)
                return entities
            } else {
                throw ParserJSONToCoreDataError.failCreateRellation(className: relationshipName, inParent: parent)
            }
        } else {
            throw ParserJSONToCoreDataError.unknowDataTypeForRellation(className: relationshipName, inParent: parent)
        }
    }

    private func union<C: NSManagedObject>(value: [[String: NSObject]], relationshipName: String, parent: C) throws -> NSObject {
        let type = parent.classType(relationshipName: relationshipName)
        let array = try addEntityArray(value, modelType: type)
        let parsedRelationSet = Set(array)

        if let localRelationSet = parent.value(forKey: relationshipName) as? Set<NSManagedObject> {
            cleanupOption.markToCleanup(local: localRelationSet, parsed: parsedRelationSet, relationshipName: relationshipName, inParent: parent)
            return parsedRelationSet.union(localRelationSet) as NSSet
        } else {
            return parsedRelationSet as NSSet
        }
    }
}
