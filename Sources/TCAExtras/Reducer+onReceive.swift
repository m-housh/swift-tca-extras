import ComposableArchitecture

extension Reducer {
  
  /// Runs an operation when an action is received, generally used to set a value on the state.
  ///
  /// ## Example
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receive(Int)
  ///     ...
  ///   }
  ///
  ///   var body: some ReducerOf<Self> {
  ///     Reduce { state, action in
  ///       ...
  ///     }
  ///     .onReceive(action: \.receive) { state, number in
  ///       state.currentNumber = number
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - toAction: The action that triggers the operation.
  ///   - operation: The operation to run when the action receives a value.
  @inlinable
  public func onReceive<Value>(
    action toAction: CaseKeyPath<Action, Value>,
    operation: @escaping @Sendable (inout State, Value) -> Void
  ) -> _OnReceiveReducer<State, Action, Value> {
    .init(case: toAction, operation: .init(operation: operation))
  }
  
  /// Runs an operation when an action is received, generally used to set a value on the state.
  ///
  /// ## Example
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receive(Int)
  ///     ...
  ///   }
  ///
  ///   var body: some ReducerOf<Self> {
  ///     Reduce { state, action in
  ///       ...
  ///     }
  ///     .onReceive(action: \.receive, set: .keyPath(\.currentNumber))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - toAction: The action that triggers the operation.
  ///   - operation: The operation to run when the action receives a value.
  @inlinable
  public func onReceive<Value>(
    action toAction: CaseKeyPath<Action, Value>,
    set operation: SetOperation<State, Value>
  ) -> _OnReceiveReducer<State, Action, Value> {
    .init(case: toAction, operation: operation)
  }
}

/// Represents an operation that receives a mutable state and value and is used to set the value
/// on the state.
///
public struct SetOperation<State, Value>: Sendable {
  
  @usableFromInline
  let operation: @Sendable (inout State, Value) -> Void
  
  /// Create a set operation using the given operation handler.
  ///
  /// - Parameters:
  ///   - operation: The operation used to set the value on the state.
  @inlinable
  public init(operation: @escaping @Sendable (inout State, Value) -> Void) {
    self.operation = operation
  }
  
  /// Create a set operation using the given key path on the state.
  ///
  /// - Parameters:
  ///   - keyPath: The key path used to set the value on the state.
  @inlinable
  public static func keyPath(_ keyPath: WritableKeyPath<State, Value>) -> Self {
    .init { $0[keyPath: keyPath] = $1 }
  }
  
  /// Create a set operation using the given key path on the state.
  ///
  /// - Parameters:
  ///   - keyPath: The key path used to set the value on the state.
  @inlinable
  public static func keyPath(_ keyPath: WritableKeyPath<State, Value?>) -> Self {
    .init { $0[keyPath: keyPath] = $1 }
  }
  
  @usableFromInline
  func callAsFunction(state: inout State, value: Value) -> Void {
    operation(&state, value)
  }
}

public struct _OnReceiveReducer<State, Action, Value>: Reducer {
  
  @usableFromInline
  let toValue: (Action) -> Value?
  
  @usableFromInline
  let operation: SetOperation<State, Value>
  
  @usableFromInline
  init(
    toValue: @escaping (Action) -> Value?,
    operation: SetOperation<State, Value>
  ) {
    self.toValue = toValue
    self.operation = operation
  }
  
  @usableFromInline
  init(
    case toValue: CaseKeyPath<Action, Value>,
    operation: SetOperation<State, Value>
  ) {
    self.init(toValue: AnyCasePath(toValue).extract(from:), operation: operation)
  }
  
  
  @inlinable
  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    if let value = toValue(action) {
      operation(state: &state, value: value)
    }
    return .none
  }
  
}
