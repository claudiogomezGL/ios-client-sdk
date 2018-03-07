//
//  LDFlagCache.swift
//  Darkly
//
//  Created by Mark Pokorny on 7/24/17. +JMJ
//  Copyright © 2017 LaunchDarkly. All rights reserved.
//

import Foundation

/*

 protocol UserStorage {
     func storeUsr(user: User)
     var allUsers: [User] { get }
 }

 class DefaultUserStorage: UserStorage {
     let defaults: UserDefaults
     init(defaults = UserDefaults.shared) { ... }
 }

 beforeEach {
     user = .stub()
     store(user: user)
     result = allUsers.filter { $0.key == user.key }
 }

 expect(user).to(equal(result))

 class FlagCache {
 let storage: UserStorage
 }

 expect(storageMock.storeUserCallCount).to(equal(1))
 expect(storageMock.storeUserRecivedUser).to(equal(user))

 typealias FlagDicationar = [String: Any]
 prptoocol FlagMigrator {
     func translateLocalDataToCurrentFormat() -> FlagDictionary
 }

 class DataMigrator: FlagMigrator {
     /// implement that method in such a way that it ....
 }

 beforeEach {
     let data = ....
      let result = FlagMigator().migrate(data)
 }

 expect(result).to(equal(someKnownOutput))

*/

//sourcery: AutoMockable
protocol UserFlagCaching {
    func cacheFlags(for user: LDUser)
    //sourcery: DefaultReturnValue = nil
    func retrieveFlags(for user: LDUser) -> CacheableUserFlags?
}

final class UserFlagCache: UserFlagCaching {
    struct Constants {
        public static let maxCachedValues = 5
    }

    struct Keys {
        fileprivate static let cachedFlags = "LDFlagCacheDictionary"
    }

    private let flagCollectionStore: FlagCollectionCaching

    init(flagCollectionStore: FlagCollectionCaching) {
        self.flagCollectionStore = flagCollectionStore
    }

    func cacheFlags(for user: LDUser) {
        var flags = cachedFlags
        flags[user.key] = CacheableUserFlags(user: user)
        cache(flags: flags)
    }
    
    func retrieveFlags(for user: LDUser) -> CacheableUserFlags? {
        return cachedFlags[user.key]
    }
    
    //TODO: Should this retrieve a tuple (userKey, flags)?
//    func retrieveLatest() -> [String: Any]? {
//        let flags = cachedFlags
//        guard !flags.isEmpty else { return nil }
//        return flags.max(by: { (pair1, pair2) -> Bool in pair1.value.lastUpdated < pair2.value.lastUpdated })?.value.flags
//    }

    private var cachedFlags: [String: CacheableUserFlags] { return flagCollectionStore.retrieveFlags() }

    private func cache(flags: [String: CacheableUserFlags]) {
        flagCollectionStore.storeFlags(flags)
    }
}

// MARK: - Test Support
#if DEBUG
    extension UserFlagCache {
        static var flagCacheKey: String { return Keys.cachedFlags }
    }
#endif