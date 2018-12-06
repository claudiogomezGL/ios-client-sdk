LaunchDarkly Migration Guide for the iOS Swift SDK
==================================================

# Getting Started
## Migration Steps
1. Integrate the v3.0.0 SDK into your app. (e.g. CocoaPods podfile or Carthage cartfile change to point to v3.0.0).
2. Clean, and delete Derived Data.
3. Update imports to `LaunchDarkly`.
4. In Swift code, replace instances of `LDClient.sharedInstance()` with `LDClient.shared`. Do not change Objective-C `[LDClient sharedInstance]` instances.
5. Update `LDUser` and properties.
6. Update `LDConfig` and properties.
7. Update `LDClient` Controls.
8. Update `LDClient` Feature Flag access
9. Install `LDClient` Observers
10. Remove `LDClientDelegate` methods if they were not re-used.

### Integrate the v3.0.0 SDK into your app using either CocoaPods or Carthage
#### CocoaPods
- Add `use_frameworks!` to either the root or to any targets that include `LaunchDarkly`

### Update imports to `LaunchDarkly`
- The module was renamed from `Darkly` to `LaunchDarkly`. Replace any `#import` that has a LD header with a single `@import LaunchDarkly;` (Objective-C) or `import LaunchDarkly` (Swift)

### Update `LDUser` and properties
- Replace any references to `LDUserBuilder` or `LDUserModel` with `LDUser`
- Replace constructor calls to use the `withKey` constructor
- Replace references to `<someUser>.ip` with `<someUser>.ipAddress`
- Replace references to `<someUser>.custom<jsonType>` with `<someUser>.custom`, and convert the object set into a `[String: Any]`

### Update `LDConfig` and properties
- Replace initializers that take a `mobileKey` with the non-mobile key initializer.
- Change lines that set `baseUrl`, `eventsUrl`, and `streamUrl` with strings to instead set these properties with `URL` objects.
- Change lines that set `capacity` to set `eventCapacity`
- Change lines that set time-based properties (`connectionTimeout`, `flushInterval`, `pollingInterval`, and `backgroundFetchInterval`) to their millisecond property (`connectionTimeoutMillis`, `flushIntervalMillis`, `pollingIntervalMillis`, and `backgroundFetchIntervalMillis`). Set these properties with `Int` values.
- Change lines that set `streaming` to set `streamingMode`. For Swift apps, use the enum `.streaming` or `.polling`. For Objective-C apps, set to `YES` for streaming, and `NO` for polling as with the v2.x SDK. Note that if you do not have this property set, LDConfig sets it to streaming mode for you.
- Change lines that set `debugEnabled` to set `debugMode` instead.

### Update `LDClient` Controls
- Replace references to `LDClient.sharedInstance()` in Swift code to `LDClient.shared`. Do not change references to `sharedInstance` in Objective-C code.
- Replace references to `ldUser` to `user`.
- Replace references to `ldConfig` to `config`.
- Remove any references to `delegate`.
- Change calls to `start` to insert the `mobileKey` as the first parameter.
- Change calls to `start` to use the parameter name `config`.
- Change calls to `start` to use the parameter name `user`.
- Change calls to `start` to not expect a return value. If desired, capture the SDK's online status using `isOnline`.
- Change calls to `stopClient` to `stop`

### Update `LDClient` Feature Flag access
- For Objective-C apps, add `ForKey` to each `variation` method call. e.g. `[[LDClient sharedInstance] boolVariationForKey:some-key fallback:fallback-value]`
- For Swift apps remove the type in the variation call, and add `forKey:` to the first parameter. e.g. `LDClient.shared.variation(forKey: some-key, fallback: fallback-value)`.
- Replace calls to `numberVariation` with `integerVariation` or `doubleVariation` as appropriate. Replace the type of the `integerVariation` call with `Int` (Swift) or `NSInteger` (Objective-C). For Objective-C apps, the client can wrap the result into an NSNumber if needed.

### Install `LDClient` Observers
For any object (Swift enum and struct cannot be feature flag observers) that conformed to `LDClientDelegate`, set observers on the `LDClient` that correspond to the implemented delegate methods. Use the steps below as a guide.
- `featureFlagDidUpdate` was called whenever any feature flag was updated. Assess the feature flags the former delegate was interested in.
  1. If the object watches a single feature flag, use `observer(key:, owner:, handler:)`. You can call the original delegate method from the `handler`, or copy the code in the delegate method into the handler. The `LDChangedFlag` passed into the handler has the `key` for the changed flag.
  2. If the object watches a set of feature flags, but not all of them in the environment, use `observe(keys:, owner:, handler:)`. As with 1 above, you can call the original delegate method by looping through the keys in the `[LDFlagKey, LDChangedFlag]` passed into the handler. Or you may copy the delegate method code into the handler. Each changed feature flag has an entry in `changedFlags` that contains a `LDChangedFlag` you can use to update the client app.
  3. If the object watches all of the feature flags in an environment (available with a specific `mobileKey`) use `observeAll(owner: , handler:)`. Follow the guidance in #2 above to unpack changed feature flag details.
- `userDidUpdate` was called whenever any feature flag changed. Follow the guidance under `featureFlagDidUpdate` to decide which observer method to call on the client.
- `userUnchanged` was called in `.polling` mode when the response to a flag request did not change any feature flag value. If your app uses `.streaming` mode (whether you set it explicitly or accept the default value in `LDConfig`) you can ignore this method. If using `.polling` mode, call `observeFlagsUnchanged` and either call the delegate method from within the handler, or copy the delegate method code into the handler.
- `serverConnectionUnavailable` was called when the SDK could not connect to LaunchDarkly servers. Set `onServerUnavailable` with a closure to execute when that occurs. Unlike the `observe` methods above, the SDK can only accept 1 `onServerUnavailable` closure. When the object that sets the closure no longer needs to watch for this condition, set `onServerUnavailable` to `nil` or set another closure from another interested object. If a client app has several objects that watch this condition, consider setting the observer in the `AppDelegate` and posting a notification from the closure.

### Remove `LDClientDelegate` methods.
If they were not re-used when implementing observers, you can delete the former `LDClientDelegate` methods.

---
## API Differences from v2.x
This section details the changes between the v2.x and v3.0.0 APIs.

### Multiple Environments
Version 3.0.0 does not support multiple environments. If you use version 2.14.0 or later and set LDConfig's `secondaryMobileKeys` you will not be able to migrate to version 3.0.0. Multiple Environments will be added in a future release to the Swift SDK.

### Configuration with LDConfig
LDConfig has changed to a `struct`, and therefore uses value semantics.

#### Changed `LDConfig` Properties
##### `mobileKey`
LDConfig no longer contains a mobileKey. Instead, pass the mobileKey into LDClient's `start` method.
##### URL properties (`baseUrl`, `eventsUrl`, and `streamUrl`)
These properties have changed to `URL` objects. Set these properties by converting URL strings to a URL using:
```swift
    ldconfig.baseUrl = URL(string: "https://custom.url.string")!
```
##### `capacity`
This property has changed to `eventCapacity`.
##### Time based properties (`connectionTimeout`, `flushInterval`, `pollingInterval`, and `backgroundFetchInterval`)
These properties have changed to `Int` properties representing milliseconds. The names have changed by appending `Millis` to the v2.x names.
##### `streaming`
This property has changed to `streamingMode` and to an enum type `LDStreamingMode`. The default remains `.streaming`. To set polling mode, set this property to `.polling`.
##### `debugEnabled`
This property has changed to `debugMode`.

#### New `LDConfig` Properties and Methods
##### `enableBackgroundUpdates`
Set this property to `true` to allow the SDK to poll while running in the background.
**NOTE**: Background polling requires additional client app support.
##### `startOnline`
Set this property to `false` if you want the SDK to remain offline after you call `start()`
##### `Minima`
We created the Minima struct and defined polling and background polling minima there. This allows the client app to ensure the values set into the corresponding properties meet the requirements for those properties. Access these via the `minima` property on your LDConfig struct.
##### `==`
LDConfig conforms to `Equatable`.

#### `LDConfig` Objective-C Compatibility
Since Objective-C does not represent `struct` items, the SDK wraps the LDConfig into a `NSObject` based wrapper with all the same properties as the Swift `struct`. The class `ObjcLDConfig` encapsulates the wrapper class. Objective-C client apps should refer to `LDConfig` and allow the Swift runtime to handle the conversion. Mixed apps can use the `LDConfig` var `objcLdConfig` to vend the Objective-C wrapper if needed to pass the `LDConfig` to an Objective-C method.
The type changes mentioned above all apply to the Objective-C LDConfig. `Int` types become `NSInteger` types in Objective-C, replacing `NSNumber` objects from v2.x.
An Objective-C `isEqual` method provides LDConfig object comparison capability.

### Custom users with `LDUser`
`LDUser` replaces `LDUserBuilder` and `LDUserModel` from v2.x. `LDUser` is a Swift `struct`, and therefore uses value semantics.
#### Changed `LDUser` Properties
Since the only required property is `key`, all other properties are Optional. While this is not really a change from v2.x, it is more explicit in Swift and may require some Optional handling that was not required in v2.x.
##### `ip`
This property has changed to `ipAddress`.
##### `custom<JsonType>`
This property has changed to `custom` and its type has also changed to [String: Any]?.

#### New `LDUser` Properties and Methods
##### `CodingKeys`
We added coding keys for all of the user properties. If you add your own custom attributes, you might want to extend `CodingKeys` to include your custom attribute keys.
##### `privatizableAttributes`
This new static property contains a `[String]` with the attributes that can be made private. This list is used if the LDConfig has the flag `allUserAttributesPrivate` set.
##### `device`
The SDK sets this property with the system provided device string.
##### `operatingSystem`
The SDK sets this property with the system provided operating system string.
##### `init(object:)` and `init(userDictionary:)`
These methods allows you to pass in a `[String: Any]` to create a user. Any other object passed in returns a `nil`. Use the `CodingKeys` to set user properties in the dictionary.
##### `==`
LDUser conforms to `Equatable`.

#### `LDUser` Objective-C Compatibility
Since Objective-C does not represent `struct` items, the SDK wraps the LDUser into a `NSObject` based wrapper with all the same properties as the Swift `struct`. The class `ObjcLDUser` encapsulates the wrapper class. Objective-C client apps should refer to `LDUser` and allow the Swift runtime to handle the conversion. Mixed apps can use the `LDUser` var `objcLdUser` to vend the Objective-C wrapper if needed to pass the `LDUser` to an Objective-C method.
An Objective-C `isEqual` method provides LDConfig object comparison capability.
##### `CodingKeys`
Since `CodingKeys` is not accessible to Objective-C, we defined class vars for attribute names, allowing you to define a user dictionary that you can pass into constructors.
##### Constructors
The new constructors added to Swift were translated to Objective-C also. Use `[[LDUser alloc] initWithObject:]` and `[[LDUser alloc] initWithUserDictionary:]` to access them.
##### `isEqual`
An Objective-C `isEqual` method provides `LDUser` object comparison capability.

### `LDClient` Controls
#### Changed `LDClient` Properties & Methods
##### `sharedInstance`
This property has changed to `shared`.
##### `ldUser`
This property has changed to `user` and its type has changed to `LDUser`. Client apps can set the `user` directly.
##### `ldConfig`
This property has changed to `config`. Client apps can set the `config` directly.
##### `delegate`
This property was removed. See [Replacing LDClient delegate methods](#replacing-ld-client-delegate)
##### `start`
- This method has a new `mobileKey` first parameter.
- `inputConfig` has changed to `config`.
- `withUserBuilder` has changed to `user` and its type changed to `LDUser`
- `completion` was added to get a callback when the SDK has completed starting
- The return value has been removed. Use `isOnline` to determine the SDK's online status.
##### `stopClient`
This method was renamed to `stop()`
##### `updateUser`
This method was removed. Set the `user` property instead.

#### New `LDClient` Properties
##### `onServerUnavailable()`
This property sets a closure called when the SDK is unable to contact the LaunchDarkly servers. The SDK keeps a strong reference to this closure. Remove this closure from the client before the owning object goes out of scope.

#### Objective-C `LDClient` Compatibility
`LDClient` does not inherit from NSObject, and is therefore not directly available to Objective-C. Instead, the class `ObjcLDClient` wraps the LDClient. Since the wrapper inherits from NSObject, Objective-C apps can access the LDClient. We have defined the Objective-C name for `ObjcLDClient` to `LDClient`, so you access the client through `LDClient` just as before.

`shared` isn't used with Objective-C, continue to use `sharedInstance`.

### Getting Feature Flag Values
#### `variation()`
Swift Generics allowed us to combine the `variation` methods that were used in the v2.x SDK. v3.0.0 has a single `variation` method that returns a type that matches the type the client app provides in the `fallback` parameter.
#### `variationAndSource()`
A new `variationAndSource()` method returns a tuple `(value, source)` that allows the client app to see what the source of the value was. `source` is an `LDFlagValueSource` enum with `.server`, `.cache`, and `.fallback`.
#### `allFlagValues`
A new computed property `allFlagValues` returns a `[LDFlagKey: Any]` that has all feature flag keys and their values. This dictionary is a snapshot taken when `allFlagValues` was requested. The SDK does not try to keep these values up-to-date, and does not record any events when accessing the dictionary.
#### Objective-C Feature Flag Value Compatibility
Swift generic functions cannot operate in Objective-C. The `ObjcLDClient` wrapper retains the type-based variation methods used in v2.x, except for `numberVariation`. A new `integerVariation` method reports NSInteger feature flags. NSNumbers that were decimal numbers should use `doubleVariation`.

The wrapper also includes new type-based `variationAndSource` methods that return a type-based `VariationValue` object (e.g. `LDBoolVariationValue`) that encapsulates the `value` and `source`. `source` is an `ObjcLDFlagValueSource` Objective-C int backed enum (accessed in Objective-C via `LDFlagValueSource`). In addition to `server`, `cache`, and `fallback`, `nilSource`, and `typeMismatch` could be possible values.

### Monitoring Feature Flags for changes
v3.0.0 removes the `LDClientDelegate`, which included `featureFlagDidUpdate` and `userDidUpdate` that the SDK called to notify client apps of changes in the set of feature flags for a given mobile key (called the environment), and the `userUnchanged` that the SDK called in `.polling` mode when the response to a feature flag request did not change any feature flag value. In order to have the SDK notify the client app when feature flags change, we have provided a closure based observer API.
#### Single-key `observe()`
To monitor a single feature flag, set a callback handler using `observe(key:, owner:, handler:)`. The SDK will keep a weak reference to the `owner`. When an observed feature flag changes, the SDK executes the closure, passing into it an `LDChangedFlag` that provides the `key`, `oldValue`, `oldValueSource`, `newValue`, and `newValueSource`. The client app can use this to update itself with the new value, or use the closure as a trigger to make another `variation` request from the LDClient.
#### Multiple-key `observe()`
To monitor a set of feature flags, set a callback handler using `observe(keys: owner: handler:)`. This functions similar to the single feature flag observer. When any of the observed feature flags change, the SDK will call the closure one time. The closure takes a `[LDFlagKey: LDChangedFlag]` which the client app can use to update itself with the new values.
#### All-Flags `observeAll()`
To monitor all feature flags in an environment, set a callback handler using `observeAll()`. This functions similar to the multiple-key feature flag observer. When any feature flag in the environment changes, the SDK will call the closure one time.
#### `observeFlagsUnchanged()`
To monitor when a polling request completes with no changes to the environment, set a callback handler using `observeFlagsUnchanged()`. If the SDK is in `.polling` mode, and a flag request did not change any flag values, the SDK will call this closure. (NOTE: In `.streaming` mode, there is no event that signals flags are unchanged. Therefore this callback will be ignored in `.streaming` mode). This method effectively replaces the LDClientDelegate method `userUnchanged`.
#### `stopObserving()`
To discontinue monitoring all feature flags for a given object, call this method. Note that this is not required, the SDK will only keep a weak reference to observers. When the observer goes out of scope, the SDK reference will be nil'd out, and the SDK will no longer call that handler.
#### Objective-C Observer Support
The LDClient wrapper provides type-based single-key observer methods that function as described above. The only difference is that the object passed into the observer block will contain type-based Objective-C wrappers for `LDChangedFlag`. `observeKeys` provides multiple-key observing, and `observeAllKeys` provides all-key observing. These function as described above, except that the dictionary passed into the handler will contain Objective-C type-based wrappers that encapsulate the LDChangedFlag properties.

### Event Controls
#### Changed Event Controls
##### `flush`
This method has changed to `reportEvents()`.
##### `track`
This method has changed to `trackEvent`

## Replacing LDClient delegate methods
### `featureFlagDidUpdate` and `userDidUpdate`
The `observe` methods provide the ability to monitor feature flags individually, as a collection, or the whole environment. The SDK will release these observers when they go out of scope, so you can set and forget them. Of course if you need to stop observing you can do that also.
### `userUnchanged`
The `observeFlagsUnchanged` method sets an observer called in `.polling` mode when a flag request leaves the flags unchanged, effectively replacing `userUnchanged`.
### `onServerUnavailable`
This property sets a closure the SDK will execute if it cannot connect to LaunchDarkly's servers, effectively replacing `serverConnectionUnavailable`. Only 1 closure can be set at a time, and the SDK keeps a strong reference to that closure.