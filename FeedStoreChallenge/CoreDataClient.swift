//
//  CoreDataClient.swift
//  FeedStoreChallenge
//
//  Created by Satbot on 14/6/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataClient {
    
    private let persistentContainer: PersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    public init(completion: @escaping () -> Void) {
        let momdName = "FeedStore"
        
        guard let modelURL = Bundle(for: type(of: self)).url(forResource: momdName, withExtension: "momd") else {
            fatalError("Error loading model from bundle.")
        }
        
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initialising mom from: \(modelURL)")
        }
        
        persistentContainer = PersistentContainer(name: momdName, managedObjectModel: mom)
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                fatalError("Failed to load core data stack: \(error)")
            }
            
            completion()
        }
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    public func saveContext(backgroundContext: NSManagedObjectContext? = nil) {
        persistentContainer.saveContext(backgroundContext: backgroundContext)
    }
}

class PersistentContainer: NSPersistentContainer {
    
    func saveContext(backgroundContext: NSManagedObjectContext? = nil) {
        let context = backgroundContext ?? viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            print("Error: \(error), \(error.userInfo)")
        }
    }
}
