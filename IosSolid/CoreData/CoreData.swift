//
//  CoreData.swift
//  Agronom
//
//  Created by Grigory Sapogov on 17.11.2023.
//

import CoreData

public
enum SaveStatus {
    case saved
    case hasNoChanges
    case error(Error)
}

extension SaveStatus {
    
    func result(_ objectName: String) -> Error? {
        switch self {
        case .hasNoChanges, .saved:
            return nil
        default:
            return StorageError.saveFailure(objectName)
        }
    }
    
}

public enum StoreType: String {
    case sql = "SQLite"
    case inMemory = "InMemory"
    case binary = "Binary"
}

class CoreData {
    
    public var model: String
    
    public var automaticallyMergesChangesFromParent: Bool
    
    public var persistentContainer: Any?
    
    public var persistentStoreCoordinator: NSPersistentStoreCoordinator?
    
    public var viewContext: NSManagedObjectContext
    
    public var privateContext: NSManagedObjectContext
    
    public var storeType: StoreType? {
        guard let type = persistentStoreCoordinator?.persistentStores.first?.type else { return nil }
        guard let storeType = StoreType(rawValue: type) else { return nil }
        return storeType
    }
    
    public required init(model: String, automaticallyMergesChangesFromParent: Bool = true, forStoreType storeType: StoreType = .sql) {
        
        self.model = model
        self.automaticallyMergesChangesFromParent = automaticallyMergesChangesFromParent
        
        var localPersistentStoreCoordinator: NSPersistentStoreCoordinator!
        var localMainViewContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        let localPrivateContext: NSManagedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        let container = NSPersistentContainer(name: self.model)
        
        if let storeDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last {
            let storeUrl = storeDirectory.appendingPathComponent("\(model).sqlite")
            let storeDescription = NSPersistentStoreDescription(url: storeUrl)
            storeDescription.type = storeType.rawValue
            container.persistentStoreDescriptions = [storeDescription]
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            Log.debug("CoreData", "Inited \(storeDescription)")
            guard error == nil else {
                Log.debug("CoreData", "Unresolved error \(error!)")
                return
            }
        }
        
        localPersistentStoreCoordinator = container.persistentStoreCoordinator
        localMainViewContext = container.viewContext
        
        self.persistentContainer = container
        
        self.persistentStoreCoordinator = localPersistentStoreCoordinator
        
        localMainViewContext.persistentStoreCoordinator = localPersistentStoreCoordinator
        localPrivateContext.persistentStoreCoordinator = localPersistentStoreCoordinator
        
        localMainViewContext.automaticallyMergesChangesFromParent = self.automaticallyMergesChangesFromParent
        localPrivateContext.automaticallyMergesChangesFromParent = self.automaticallyMergesChangesFromParent
        
        self.viewContext = localMainViewContext
        self.privateContext = localPrivateContext
        
    }
    
    public func createChildContext(for concurrencyType: NSManagedObjectContextConcurrencyType, from context: NSManagedObjectContext?) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.parent = context ?? self.viewContext
        if #available(iOS 10.0, *) {
            managedObjectContext.automaticallyMergesChangesFromParent = self.automaticallyMergesChangesFromParent
        }
        return managedObjectContext
    }
    
    @available(iOS 10.0, *)
    public func createChildContext(for concurrencyType: NSManagedObjectContextConcurrencyType, from context: NSManagedObjectContext?, mergePolicy: NSMergePolicy) -> NSManagedObjectContext {
        let managedObjectContext = self.createChildContext(for: concurrencyType, from: context)
        managedObjectContext.mergePolicy = mergePolicy
        return managedObjectContext
    }
    
    public func createChildContextFromCoordinator(for concurrencyType: NSManagedObjectContextConcurrencyType, automaticallyMergesChangesFromParent: Bool = false) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.viewContext.persistentStoreCoordinator
        if #available(iOS 10.0, *) {
            managedObjectContext.automaticallyMergesChangesFromParent = automaticallyMergesChangesFromParent
        }
        return managedObjectContext
    }
    
    @available(iOS 10.0, *)
    public func createChildContextFromCoordinator(for concurrencyType: NSManagedObjectContextConcurrencyType, mergePolicy: NSMergePolicy, automaticallyMergesChangesFromParent: Bool = false) -> NSManagedObjectContext {
        let managedObjectContext = self.createChildContextFromCoordinator(for: concurrencyType, automaticallyMergesChangesFromParent: automaticallyMergesChangesFromParent)
        managedObjectContext.mergePolicy = mergePolicy
        return managedObjectContext
    }
    
    @available(iOS 10.0, *)
    public func backgroundTask(block: @escaping (_ privateContext: NSManagedObjectContext) -> Void) {
        self.backgroundTask(mergePolicy: .error, block: block)
    }
    
    @available(iOS 10.0, *)
    public func backgroundTask(mergePolicy: NSMergePolicy, block: @escaping (_ privateContext: NSManagedObjectContext) -> Void) {
        (persistentContainer as? NSPersistentContainer)?.performBackgroundTask { privateContext in
            privateContext.mergePolicy = mergePolicy
            block(privateContext)
        }
    }
    
    // MARK: - FetchedResultController
    
    public func fetchedResultController<T: NSManagedObject>(
        entity: String,
        sectionKey: String?,
        cacheName: String?,
        sortKey: String?,
        sortKeys: [String]?,
        sortDescriptors: [NSSortDescriptor]?,
        fetchPredicates: [NSPredicate]?,
        ascending: Bool,
        batchSize: Int?,
        fetchContext: NSManagedObjectContext?
    ) -> NSFetchedResultsController<T> {
        
        let context = fetchContext ?? self.viewContext
        
        // Create Fetch Request
        let fetchRequest = NSFetchRequest<T>(entityName: entity)
        
        // Configure Fetch Request
        if let sortDescriptors = sortDescriptors {
            fetchRequest.sortDescriptors = sortDescriptors
        }
        else if let sortKeys = sortKeys {
            fetchRequest.sortDescriptors = sortKeys.map { NSSortDescriptor(key: $0, ascending: ascending) }
        } else if let sortKey = sortKey {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: ascending)]
        }
        
        // Configure Fetch Predicates
        if let fetchPredicates = fetchPredicates {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: fetchPredicates)
        }
        
        //Configure batch size
        if let batchSize = batchSize {
            fetchRequest.fetchBatchSize = batchSize
        }
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionKey, cacheName: cacheName)
        
        return fetchedResultsController
    }
    
    
    // MARK: - Save
    
    public func save(in context: NSManagedObjectContext?, result: ((_ status: SaveStatus) -> Void)?) {
        let context = context ?? self.viewContext
        if context.hasChanges {
            do {
                try context.save()
                result?(.saved)
            } catch {
//                Log.debug("Core Data rolled back on save", error)
//                context.rollback()
                Log.debug("Core Data error on save", error)
                result?(.error(error))
            }
        } else {
            result?(.hasNoChanges)
        }
    }
    
    
    // MARK: - Create
    
    public func new<T: NSManagedObject>(entity: String, in context: NSManagedObjectContext?) -> T {
        return NSEntityDescription.insertNewObject(forEntityName: entity, into: context == nil ? self.viewContext : context!) as! T
    }
    
    
    // MARK: - Fetch
    
    public func fetch<T: NSManagedObject>(
        entity: String,
        predicates: [NSPredicate],
        sort: [NSSortDescriptor]?,
        from: Int?,
        count: Int?,
        in context: NSManagedObjectContext?) -> [T] {
            return fetch(entity: entity, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates), sort: sort, from: from, count: count, in: context)
        }
    
    public func fetch<T: NSManagedObject>(
        entity: String,
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]?,
        from: Int?,
        count: Int?,
        in context: NSManagedObjectContext?) -> [T] {
            
            do {
                let fetchRequest = NSFetchRequest<T>(entityName: entity)
                fetchRequest.predicate = predicate
                fetchRequest.sortDescriptors = sort
                fetchRequest.returnsObjectsAsFaults = false
                if count != nil {
                    fetchRequest.fetchLimit = count!
                }
                if from != nil {
                    fetchRequest.fetchOffset = from!
                }
                
                let context = context ?? self.viewContext
                let result = try context.fetch(fetchRequest)
                
                if result.count == 0 {
                    return []
                } else {
                    return result
                }
            } catch let error {
                Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
                return []
            }
        }
    
    public func fetchOne<T: NSManagedObject>(
        entity: String,
        predicates: [NSPredicate],
        sort: [NSSortDescriptor]?,
        from: Int?,
        in context: NSManagedObjectContext?) -> T? {
            
            return fetchOne(entity: entity, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates), sort: sort, from: from, in: context)
        }
    
    public func fetchOne<T: NSManagedObject>(
        entity: String,
        predicate: NSPredicate?,
        sort: [NSSortDescriptor]?,
        from: Int?,
        in context: NSManagedObjectContext?) -> T? {
            
            let result = fetch(entity: entity, predicate: predicate, sort: sort, from: from, count: 1, in: context)
            return result.count > 0 ? result[0] as? T : nil
        }
    
    public func fetch<T: NSManagedObject>(entity: String, in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            let context = context ?? self.viewContext
            let result = try context.fetch(fetchRequest)
            return result
        } catch let error {
            Log.debug("CoreData", "Could not load \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, for idName: String, value: String, in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSPredicate(format: "\(idName) == %@", value as NSString)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, for idName: String, value: Int, in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSPredicate(format: "\(idName) == %@", value as NSNumber)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, for idName: String, value: Bool, in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSPredicate(format: "\(idName) == %@", value as NSNumber)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, format: String, value: Any, in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSPredicate(format: format, value as! CVarArg)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSDictionary>(entity: String, fetchPredicates: [NSPredicate], properties: [String], in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: fetchPredicates)
            fetchRequest.resultType = .dictionaryResultType
            fetchRequest.returnsObjectsAsFaults = false
            if !properties.isEmpty {
                fetchRequest.propertiesToFetch = properties
            }
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, fetchPredicates: [NSPredicate], in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: fetchPredicates)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    public func fetch<T: NSManagedObject>(entity: String, orFetchPredicates fetchPredicates: [NSPredicate], in context: NSManagedObjectContext?) -> [T]? {
        do {
            let fetchRequest = NSFetchRequest<T>(entityName: entity)
            fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: fetchPredicates)
            fetchRequest.returnsObjectsAsFaults = false
            
            let context = context == nil ? self.viewContext : context!
            let result = try context.fetch(fetchRequest)
            
            return result
            
        } catch let error {
            Log.debug("CoreData", "Could not fetch \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: - Remove
    
    public func delete<T: NSManagedObject>(_ data: T, from context: NSManagedObjectContext?, result: ((_ status: SaveStatus) -> Void)?) {
        
        let context = context == nil ? self.viewContext : context!
        context.delete(data)
        
        save(in: context, result: result)
    }
    
    
    // MARK: - Clean
    
    public func clean(entity: String, predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, mergeIntoContexts contexts: [NSManagedObjectContext] = [], result: ((_ status: SaveStatus) -> Void)?) {
        
        switch self.storeType {
        case .inMemory:
            cleanInMemory(entity: entity, predicates: predicates, in: context, result: result)
        default:
            cleanInBatch(entity: entity, predicates: predicates, in: context, mergeIntoContexts: contexts, result: result)
        }
        
    }
    
    public func clean(entity: String, orPredicates predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, mergeIntoContexts contexts: [NSManagedObjectContext] = [], result: ((_ status: SaveStatus) -> Void)?) {
        
        switch self.storeType {
        case .inMemory:
            cleanInMemory(entity: entity, orPredicates: predicates, in: context, result: result)
        default:
            cleanInBatch(entity: entity, orPredicates: predicates, in: context, mergeIntoContexts: contexts, result: result)
        }
        
    }
    
    private func cleanInMemory(entity: String, predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, result: ((_ status: SaveStatus) -> Void)?) {
        let predicates = predicates ?? []
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        cleanInMemory(entity: entity, predicate: predicate, in: context, result: result)
    }
    
    private func cleanInMemory(entity: String, orPredicates predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, result: ((_ status: SaveStatus) -> Void)?) {
        let predicates = predicates ?? []
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        cleanInMemory(entity: entity, predicate: predicate, in: context, result: result)
    }
    
    private func cleanInMemory(entity: String, predicate: NSPredicate, in context: NSManagedObjectContext?, result: ((_ status: SaveStatus) -> Void)?) {
        let context = context == nil ? self.viewContext : context!
        
        do {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
            fetchRequest.predicate = predicate
            let array = try context.fetch(fetchRequest)
            for object in array {
                context.delete(object)
            }
            result?(.saved)
        }
        catch {
            result?(.error(error))
        }
        
    }
    
    private func cleanInBatch(entity: String, predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, mergeIntoContexts contexts: [NSManagedObjectContext] = [], result: ((_ status: SaveStatus) -> Void)?) {
        let predicates = predicates ?? []
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        cleanInBatch(entity: entity, predicate: predicate, in: context, mergeIntoContexts: contexts, result: result)
    }
    
    private func cleanInBatch(entity: String, orPredicates predicates: [NSPredicate]? = nil, in context: NSManagedObjectContext? = nil, mergeIntoContexts contexts: [NSManagedObjectContext] = [], result: ((_ status: SaveStatus) -> Void)?) {
        let predicates = predicates ?? []
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        cleanInBatch(entity: entity, predicate: predicate, in: context, result: result)
    }
    
    private func cleanInBatch(entity: String, predicate: NSPredicate, in context: NSManagedObjectContext?, mergeIntoContexts contexts: [NSManagedObjectContext] = [], result: ((_ status: SaveStatus) -> Void)?) {
        
        let context = context == nil ? self.viewContext : context!
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        do {
            let results = try context.execute(deleteRequest) as! NSBatchDeleteResult
            let changes: [AnyHashable: Any] = [
                NSDeletedObjectsKey: results.result as! [NSManagedObjectID]
            ]
            if !contexts.isEmpty {
                Log.debug("CoreData", "start merging")
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: contexts)
                Log.debug("CoreData", "end merging")
            }
            result?(.saved)
        } catch {
            Log.debug("CoreData", "Could not clean \(error.localizedDescription)")
            result?(.error(error))
        }
        
    }
    
    //MARK: - Count
    
    
}
