# Attribute Graph internals

I looked a bit at trying to understand the attribute graph better. I used the following commands:

```fish
nm -C "/Library/Developer/CoreSimulator/Volumes/iOS_22B81/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.1.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/AttributeGraph.framework/AttributeGraph" | pbcopy
nm -C "./CoreSimulator/Volumes/iOS_22A5282m/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.0.simruntime/Contents/Resources/RuntimeRoot/System/Library/Frameworks/SwiftUI.framework/SwiftUI" | xcrun swift-demangle | grep DisplayList | grep -v "specialization" | grep -v "partial" > ~/Downloads/displaylist2.txt
```

I did this for the display list, view inputs and view outputs. I then fed the output into an LLM to try to turn this into something readable. Here's what I got. I don't really have an idea whether this actually represents reality:

```swift
struct _ViewInputs {
    // Base properties
    var base: _GraphInputs
    
    // Environment
    var environment: AttributeGraph.Attribute<EnvironmentValues>
    var transaction: AttributeGraph.Attribute<Transaction>
    var time: AttributeGraph.Attribute<Time>
    
    // Layout related
    var size: AttributeGraph.Attribute<ViewSize>
    var position: AttributeGraph.Attribute<ViewOrigin>
    var transform: AttributeGraph.Attribute<ViewTransform>
    var containerPosition: AttributeGraph.Attribute<ViewOrigin>
    
    // Flags and states
    var needsGeometry: Bool
    var needsAccessibilityGeometry: Bool
    var needsDisplayListAccessibility: Bool
    var needsAccessibilityViewResponders: Bool
    var requestsLayoutComputer: Bool
    
    // Optional attributes
    var safeAreaInsets: AttributeGraph.OptionalAttribute<SafeAreaInsets>
    var scrollableContainerSize: AttributeGraph.OptionalAttribute<ViewSize>
    
    // Additional properties
    var customInputs: PropertyList
    var preferences: PreferencesInputs
    var stackOrientation: Axis?
    var viewPhase: AttributeGraph.Attribute<_GraphInputs.Phase>
    
    // Initialization
    init(
        _ inputs: _GraphInputs,
        position: AttributeGraph.Attribute<ViewOrigin>,
        size: AttributeGraph.Attribute<ViewSize>,
        transform: AttributeGraph.Attribute<ViewTransform>,
        containerPosition: AttributeGraph.Attribute<ViewOrigin>,
        hostPreferenceKeys: AttributeGraph.Attribute<PreferenceKeys>
    )
    
    // MARK: - Methods
    
    /// Reset all caches
    func resetCaches()
    
    /// Copy all caches
    func copyCaches()
    
    /// Create inputs without geometry dependencies
    var withoutGeometryDependencies: _ViewInputs { get }
    
    /// Map environment to a specific type
    func mapEnvironment<T>(_ keyPath: KeyPath<EnvironmentValues, T>) -> AttributeGraph.Attribute<T>
    
    /// Get animated size
    func animatedSize() -> AttributeGraph.Attribute<ViewSize>
    
    /// Get animated position
    func animatedPosition() -> AttributeGraph.Attribute<ViewOrigin>
    
    /// Get animated CGSize
    func animatedCGSize() -> AttributeGraph.Attribute<CGSize>
}
```

This is the outputs type:


```swift
// SwiftUI ViewOutputs Interface
import SwiftUI
import AttributeGraph

extension SwiftUI {
    /// Represents the outputs from a SwiftUI view's layout and rendering process
    struct _ViewOutputs {
        // MARK: - Properties
        
        /// Preferences collected from the view hierarchy
        var preferences: PreferencesOutputs
        
        /// Optional layout computer for the view
        var layoutComputer: AttributeGraph.Attribute<LayoutComputer>?

        // MARK: - Methods
        
        /// Initialize an empty ViewOutputs instance
        init()
        
        /// Add a preference value for a given preference key
        func appendPreference<Key: PreferenceKey>(
            key: Key.Type,
            value: AttributeGraph.Attribute<Key.Value>
        )

        /// Iterate through all preferences
        func forEachPreference(_ body: (AnyPreferenceKey.Type, AGAttribute) -> Void)
        
        /// Access preferences by key type
        subscript<Key: PreferenceKey>(_ key: Key.Type) -> AttributeGraph.Attribute<Key.Value>? { get set }
        
        /// Access preferences by any preference key type
        subscript(anyKey: AnyPreferenceKey.Type) -> AGAttribute? { get set }
        
        // MARK: - View System Integration
        
        /// Attach indirect outputs to another ViewOutputs instance
        func attachIndirectOutputs(to other: _ViewOutputs)
        
        /// Detach any indirect outputs
        func detachIndirectOutputs()
        
        /// Get view responders from the output
        func viewResponders() -> AttributeGraph.Attribute<[ViewResponder]>
        
        /// Set an indirect dependency
        func setIndirectDependency(_ dependency: AGAttribute?)
        
        /// Apply interpolator group for animations
        func applyInterpolatorGroup<Content: InterpolatableContent>(
            _ group: DisplayList.InterpolatorGroup,
            content: AttributeGraph.Attribute<Content>,
            inputs: _ViewInputs,
            animatesSize: Bool,
            defersRender: Bool
        )
    }
}

// MARK: - Related View Protocols

extension View {
    /// Create view outputs from graph value and inputs
    static func _makeView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs
    
    /// Create debug view outputs
    static func makeDebuggableView(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs
    
    /// Create implicit root view outputs
    static func makeImplicitRoot(
        view: _GraphValue<Self>,
        inputs: _ViewInputs
    ) -> _ViewOutputs
}

// MARK: - View Modifier Integration

extension ViewModifier {
    /// Create modified view outputs
    static func _makeView(
        modifier: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs
    ) -> _ViewOutputs
}

// MARK: - Layout Integration

extension Layout {
    /// Create layout view outputs
    static func _makeLayoutView(
        root: _GraphValue<Self>,
        inputs: _ViewInputs,
        body: @escaping (_Graph, _ViewInputs) -> _ViewListOutputs
    ) -> _ViewOutputs
    
    /// Create static layout view outputs
    static func makeStaticView(
        root: _GraphValue<Self>,
        inputs: _ViewInputs,
        properties: LayoutProperties,
        list: _ViewList_Elements
    ) -> _ViewOutputs
}
```

I also tried to do this with the attribute graph and asked the LLM to turn this into an interface in Swift. It's written in C++, but here's what it came up with:

```swift
/// AttributeGraph Framework Swift Interface
/// This is a reconstructed interface based on the visible symbols

// MARK: - Core Types

/// A protocol representing basic graph node behavior
public protocol Rule {
    associatedtype Value
    
    /// Optional initial value for the rule
    static var initialValue: Value? { get }
    
    /// Current value of the rule
    var value: Value { get }
}

/// A rule that can maintain state
public protocol StatefulRule: Rule {
    /// Updates the value of this rule
    func updateValue()
}

/// A protocol representing an attribute that can be observed
public protocol ObservedAttribute: _AttributeBody {
    /// Destroys the attribute
    func destroy()
}

/// Main attribute type representing a node in the dependency graph
public struct Attribute<Value> {
    /// The identifier for this attribute
    public var identifier: AGAttribute
    
    /// The current value
    public var value: Value
    
    /// The projected value when used as a property wrapper
    public var projectedValue: Attribute<Value>
    
    /// Creates an attribute with the given value
    public init(value: Value)
    
    /// Creates an attribute with the given identifier
    public init(identifier: AGAttribute)
}

/// A weak reference to an attribute
public struct WeakAttribute<Value> {
    /// The underlying attribute if still alive
    public var attribute: Attribute<Value>?
    
    /// The current value if available
    public var value: Value?
    
    /// Creates an empty weak attribute reference
    public init()
    
    /// Creates a weak reference to the given attribute
    public init(_ attribute: Attribute<Value>)
}

/// An optional attribute
public struct OptionalAttribute<Value> {
    /// The underlying attribute if present
    public var attribute: Attribute<Value>?
    
    /// The current optional value
    public var value: Value?
    
    /// Creates an empty optional attribute
    public init()
}

/// An indirect attribute that can change its source
public struct IndirectAttribute<Value> {
    /// The source attribute
    public var source: Attribute<Value>
    
    /// The current dependency
    public var dependency: AGAttribute?
    
    /// The current value
    public var value: Value
    
    /// Creates an indirect attribute with the given source
    public init(source: Attribute<Value>)
}

// MARK: - Graph Management

/// Represents a subgraph within the dependency graph
public class Subgraph {
    /// The current graph context
    public var graph: AGGraphRef
    
    /// Adds a child subgraph
    public func addChild(_ child: Subgraph)
    
    /// Removes a child subgraph
    public func removeChild(_ child: Subgraph)
    
    /// Adds an observer callback
    public func addObserver(_ callback: @escaping () -> Void) -> Int
    
    /// Removes an observer
    public func removeObserver(_ token: Int)
    
    /// Updates the subgraph
    public func update()
    
    /// Invalidates the subgraph
    public func invalidate()
}

// MARK: - Rule Context

/// Context for rule evaluation
public struct RuleContext<Value> {
    /// The attribute being evaluated
    public var attribute: Attribute<Value>
    
    /// The current value
    public var value: Value
    
    /// Whether a value is present
    public var hasValue: Bool
}

// MARK: - Utilities

/// Represents an offset between two pointer types
public struct PointerOffset<From, To> {
    /// The byte offset
    public var byteOffset: Int
    
    /// Creates an offset with the given byte count
    public init(byteOffset: Int)
}

/// A type for mapping attributes
public struct Map<Input, Output> {
    /// The input attribute
    public var arg: Attribute<Input>
    
    /// The mapping function
    public var body: (Input) -> Output
    
    /// Creates a new mapping
    public init(arg: Attribute<Input>, body: @escaping (Input) -> Output)
}

/// A focusing mechanism for attributes
public struct Focus<Root, Value> {
    /// The root attribute
    public var root: Attribute<Root>
    
    /// The key path to focus on
    public var keyPath: KeyPath<Root, Value>
    
    /// Creates a new focus
    public init(root: Attribute<Root>, keyPath: KeyPath<Root, Value>)
}

// MARK: - Conformances

extension Attribute: Hashable {}
extension Attribute: CustomStringConvertible {}

extension WeakAttribute: Hashable {}
extension WeakAttribute: CustomStringConvertible {}

extension OptionalAttribute: Hashable {}
extension OptionalAttribute: CustomStringConvertible {}

extension IndirectAttribute: Hashable {}
extension IndirectAttribute: CustomStringConvertible {}
```
