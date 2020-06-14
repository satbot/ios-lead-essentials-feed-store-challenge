//
//  InMemoryFeedStore.swift
//  FeedStoreChallenge
//
//  Created by Satbot on 14/6/20.
//  Copyright © 2020 Essential Developer. All rights reserved.
//

import Foundation

public class InMemoryFeedStore: FeedStore {
    
    private var cache: (feed: [LocalFeedImage], timestamp: Date)?
    
    public init() {}
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        cache = nil
        completion(nil)
    }
    
    public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        cache = (feed, timestamp)
        completion(nil)
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        guard let cache = cache else { return completion(.empty) }
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
    }
}
