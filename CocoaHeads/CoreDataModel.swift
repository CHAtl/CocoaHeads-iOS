//
//  CoreDataModel.swift
//  CocoaHeads
//
//  Created by Liam Butler-Lawrence on 8/3/15.
//  Copyright © 2015 Liam Butler-Lawrence. All rights reserved.
//

import UIKit
import CoreData

class CoreDataModel: NSObject {
    
    static var managedObjectContext: NSManagedObjectContext = {
        
        guard let modelURL = NSBundle.mainBundle().URLForResource("CacheModel", withExtension: "momd") else {
            fatalError("Could not create model URL")
        }
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Could not create model using model URL: \(modelURL)")
        }
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        do {
            let documentsDirectoryURL = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
            let persistentStoreURL = documentsDirectoryURL.URLByAppendingPathComponent("CoreDataCache.sqlite")
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: persistentStoreURL, options: nil)
        } catch {
            // should determine error type, enum or NSError? How to access?
            fatalError("Could not create documents directory URL, OR, Could not add persistent store to coordinator with URL: ")
        }
        
        let context = NSManagedObjectContext()
        context.persistentStoreCoordinator = coordinator
        
        return context
        }()
}

enum EntityDescriptionError: ErrorType {
    case CouldNotInsertNewObject
}

extension NSEntityDescription {
    
    class func insertNewObjectForEntityForName<T>(entityName: String) throws -> T {
        guard let newObject = insertNewObjectForEntityForName(entityName, inManagedObjectContext: CoreDataModel.managedObjectContext) as? T else {
            throw EntityDescriptionError.CouldNotInsertNewObject
        }
        return newObject
    }
}
