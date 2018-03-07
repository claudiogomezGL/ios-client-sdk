//
//  LDEvent.swift
//  Darkly
//
//  Created by Mark Pokorny on 7/11/17. +JMJ
//  Copyright © 2017 LaunchDarkly. All rights reserved.
//

import Foundation

enum LDEventType: String {
    case featureRequest, identify, custom
}

struct LDEvent { //sdk internal, not publically accessible
    enum CodingKeys: String, CodingKey {
        case key, kind, creationDate, user, value, defaultValue = "default", data
    }

    let key: String
    let kind: LDEventType
    let creationDate: Date
    let user: LDUser
    let value: LDFlagValue?
    let defaultValue: LDFlagValue?
    let data: [String: Any]?

    init(key: String, kind: LDEventType = .custom, user: LDUser, value: LDFlagValue? = nil, defaultValue: LDFlagValue? = nil, data: [String: Any]? = nil) {
        self.key = key
        self.kind = kind
        self.creationDate = Date()
        self.user = user
        self.value = value
        self.defaultValue = defaultValue
        self.data = data
    }

    static func featureRequestEvent(key: String, user: LDUser, value: LDFlagValue, defaultValue: LDFlagValue) -> LDEvent {
        return LDEvent(key: key, kind: .featureRequest, user: user, value: value, defaultValue: defaultValue)
    }

    static func customEvent(key: String, user: LDUser, data: [String: Any]? = nil) -> LDEvent {
        return LDEvent(key: key, kind: .custom, user: user, data: data)
    }

    static func identifyEvent(key: String, user: LDUser) -> LDEvent {
        return LDEvent(key: key, kind: .identify, user: user)
    }

    func dictionaryValue(config: LDConfig) -> [String: Any] {
        var eventDictionary = [String: Any]()
        eventDictionary[CodingKeys.key.rawValue] = key
        eventDictionary[CodingKeys.kind.rawValue] = kind.rawValue
        eventDictionary[CodingKeys.creationDate.rawValue] = creationDate.millisSince1970
        eventDictionary[CodingKeys.user.rawValue] = user.dictionaryValue(includeFlagConfig: false, includePrivateAttributes: false, config: config)
        eventDictionary[CodingKeys.value.rawValue] = value?.baseValue
        eventDictionary[CodingKeys.defaultValue.rawValue] = defaultValue?.baseValue
        eventDictionary[CodingKeys.data.rawValue] = data

        return eventDictionary
    }
}

extension Array where Element == LDEvent {
    func dictionaryValues(config: LDConfig) -> [[String: Any]] {
        return self.map { (event) in event.dictionaryValue(config: config) }
    }
}

extension Array where Element == [String: Any] {
    var jsonData: Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }

    func contains(eventDictionary: [String: Any]) -> Bool {
        return !self.filter { (testDictionary) in testDictionary.matches(eventDictionary: eventDictionary) }.isEmpty
    }
}

extension Dictionary where Key == String, Value == Any {
    var eventKey: String? { return self[LDEvent.CodingKeys.key.rawValue] as? String }
    var eventCreationDateMillis: Int? { return self[LDEvent.CodingKeys.creationDate.rawValue] as? Int }

    func matches(eventDictionary other: [String: Any]) -> Bool {
        guard let key = eventKey, let creationDateMillis = eventCreationDateMillis,
            let otherKey = other.eventKey, let otherCreationDateMillis = other.eventCreationDateMillis
        else { return false }
        return key == otherKey && creationDateMillis == otherCreationDateMillis
    }
}

extension LDEvent: Equatable {
    static func == (lhs: LDEvent, rhs: LDEvent) -> Bool { return lhs.key == rhs.key && lhs.creationDate == rhs.creationDate }
}