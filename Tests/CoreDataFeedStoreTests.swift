//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import XCTest
import FeedStoreChallenge

extension CoreDataClient {
    func retrieveFeedCache(from context: NSManagedObjectContext? = nil) -> (feed: [LocalFeedImage], timestamp: Date)? {
        guard
            let managedCache = retrieveManagedCache(from: context),
            let managedFeed = managedCache.feed?.array as? [ManagedLocalFeedImage],
            let cacheTimestamp = managedCache.timestamp
            else { return nil }
        
        let feed = managedFeed.compactMap { $0.localFeedImage }
        return (feed: feed, timestamp: cacheTimestamp)
    }
    
    func retrieveManagedCache(from context: NSManagedObjectContext? = nil) -> ManagedCache? {
        let context = context ?? viewContext
        let fetchRequest: NSFetchRequest<ManagedCache> = ManagedCache.fetchRequest()
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            return nil
        }
    }
}

extension CoreDataClient {
    func clearCache() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Cache")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
        } catch {
            fatalError("Failed to clear feed cache: \(error.localizedDescription)")
        }
    }
}

extension ManagedLocalFeedImage {
    
    static func from(_ localFeedImage: LocalFeedImage, in context: NSManagedObjectContext) -> ManagedLocalFeedImage {
        let managedLocalFeedImage = ManagedLocalFeedImage(context: context)
        managedLocalFeedImage.id = localFeedImage.id
        managedLocalFeedImage.imageDescription = localFeedImage.description
        managedLocalFeedImage.location = localFeedImage.location
        managedLocalFeedImage.url = localFeedImage.url
        return managedLocalFeedImage
    }
    
    var localFeedImage: LocalFeedImage? {
        guard
            let id = id,
            let url = url
            else { return nil }
        
        return LocalFeedImage(id: id,
                              description: imageDescription,
                              location: location,
                              url: url)
    }
}

class CoreDataFeedStore: FeedStore {
    
    private let coreDataClient: CoreDataClient
    
    init(_ coreDataClient: CoreDataClient) {
        self.coreDataClient = coreDataClient
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completion(nil)
    }
    
    private let queue = DispatchQueue(label: "\(CoreDataFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        queue.async(flags: .barrier) { [weak self] in
            
            guard let self = self else { return }
            let backgroundContext = self.coreDataClient.newBackgroundContext()
            
            if let feedCache = self.coreDataClient.retrieveManagedCache(from: backgroundContext) {
                backgroundContext.delete(feedCache)
            }

            let managedCache = ManagedCache.init(context: backgroundContext)
            let managedLocalFeed = NSOrderedSet(array: feed.map { ManagedLocalFeedImage.from($0, in: backgroundContext) })
            managedCache.feed = managedLocalFeed
            managedCache.timestamp = timestamp
            
            self.coreDataClient.saveContext(backgroundContext: backgroundContext)
            completion(nil)
        }
    }
    
    func retrieve(completion: @escaping RetrievalCompletion) {
        queue.async { [weak self] in
            
            guard
                let self = self
                else { return }
            
            guard
                let feedCache = self.coreDataClient.retrieveFeedCache(),
                !feedCache.feed.isEmpty
                else { return completion(.empty) }
            
            completion(.found(feed: feedCache.feed, timestamp: feedCache.timestamp))
        }
    }
}

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {

    private var coreDataClient: CoreDataClient!
    
    override func setUp() {
        let exp = XCTestExpectation(description: "Expect core data client to be initialised")
        coreDataClient = CoreDataClient() {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        coreDataClient.clearCache()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedCacheValues() {
        let sut = makeSUT()

        assertThatInsertOverridesPreviouslyInsertedCacheValues(on: sut)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
//        let sut = makeSUT()
//
//        assertThatDeleteDeliversNoErrorOnNonEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
//        let sut = makeSUT()
//
//        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_storeSideEffects_runSerially() {
//        let sut = makeSUT()
//
//        assertThatSideEffectsRunSerially(on: sut)
    }
    
    // - MARK: Helpers
    
    private func makeSUT() -> FeedStore {
        return CoreDataFeedStore(coreDataClient)
    }
    
    private func eraseCoreDataCache() {
        
    }
    
}

//
// Uncomment the following tests if your implementation has failable operations.
// Otherwise, delete the commented out code!
//

//extension FeedStoreChallengeTests: FailableRetrieveFeedStoreSpecs {
//
//    func test_retrieve_deliversFailureOnRetrievalError() {
////        let sut = makeSUT()
////
////        assertThatRetrieveDeliversFailureOnRetrievalError(on: sut)
//    }
//
//    func test_retrieve_hasNoSideEffectsOnFailure() {
////        let sut = makeSUT()
////
////        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
//    }
//
//}

//extension FeedStoreChallengeTests: FailableInsertFeedStoreSpecs {
//
//    func test_insert_deliversErrorOnInsertionError() {
////        let sut = makeSUT()
////
////        assertThatInsertDeliversErrorOnInsertionError(on: sut)
//    }
//
//    func test_insert_hasNoSideEffectsOnInsertionError() {
////        let sut = makeSUT()
////
////        assertThatInsertHasNoSideEffectsOnInsertionError(on: sut)
//    }
//
//}

//extension FeedStoreChallengeTests: FailableDeleteFeedStoreSpecs {
//
//    func test_delete_deliversErrorOnDeletionError() {
////        let sut = makeSUT()
////
////        assertThatDeleteDeliversErrorOnDeletionError(on: sut)
//    }
//
//    func test_delete_hasNoSideEffectsOnDeletionError() {
////        let sut = makeSUT()
////
////        assertThatDeleteHasNoSideEffectsOnDeletionError(on: sut)
//    }
//
//}
