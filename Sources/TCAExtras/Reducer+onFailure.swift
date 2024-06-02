import ComposableArchitecture
import Foundation
import OSLog

extension Reducer {
  /// A higher order reducer that handles errors with the given operation.
  ///
  /// ## Example
  /// ```swift
  /// @Reducer
  /// public struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receiveError(Error)
  ///     case task
  ///     ...
  ///   }
  ///
  ///   @Dependency(\.logger) var logger
  ///
  ///   var body: some ReducerOf<Self> {
  ///     Reduce { state, action in
  ///       ...
  ///     }
  ///     .onFailure(case: \.receiveError, .log(logger: logger))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - toError: Case path to the trigger action for  the error.
  ///   - onFail: The error handling logic.
  @inlinable
  public func onFailure(
    case toError: CaseKeyPath<Action, Error>,
    _ onFail: OnFailureOperation<State, Action>
  ) -> _OnFailureReducer<Self> {
    .init(
      parent: self,
      toError: .init(AnyCasePath(toError)),
      onFailAction: onFail
    )
  }

  /// A higher order reducer that handles failures of an action that excepts a `TaskResult` with the given operation.
  ///
  /// ## Example
  /// ```swift
  /// @Reducer
  /// public struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receive(TaskResult<Int>)
  ///     case task
  ///     ...
  ///   }
  ///
  ///   @Dependency(\.logger) var logger
  ///
  ///   var body: some ReducerOf<Self> {
  ///     Reduce { state, action in
  ///       ...
  ///     }
  ///     .onFailure(case: \.receive, .log(logger: logger))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - toError: Case path to the trigger action for  the error.
  ///   - onFail: The error handling logic.
  @inlinable
  public func onFailure<T>(
    case toError: CaseKeyPath<Action, TaskResult<T>>,
    _ onFail: OnFailureOperation<State, Action>
  ) -> _OnFailureReducer<Self> {
    onFailure(case: toError.appending(path: \.failure), onFail)
  }
}

extension Reducer where Action: ReceiveAction {
  /// A higher order reducer that handles failures of an action that implements the ``ReceiveAction`` protocol.
  ///
  /// ## Example
  /// ```swift
  /// @Reducer
  /// public struct MyFeature {
  ///   ...
  ///   enum Action: ReceiveAction {
  ///     case receive(TaskResult<ReceiveAction>)
  ///     case task
  ///     ...
  ///
  ///     @CasePathable
  ///     enum ReceiveAction {
  ///       case currentNumber(Int)
  ///     }
  ///   }
  ///
  ///   @Dependency(\.logger) var logger
  ///
  ///   var body: some ReducerOf<Self> {
  ///     Reduce { state, action in
  ///       ...
  ///     }
  ///     .onFailure(.log(logger: logger))
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - toError: Case path to the trigger action for  the error.
  ///   - onFail: The error handling logic.
  @inlinable
  public func onFailure(
    _ onFail: OnFailureOperation<State, Action>
  ) -> _OnFailureReducer<Self> {
    .init(
      parent: self,
      toError: .init(AnyCasePath(unsafe: Action.receive)),
      onFailAction: onFail
    )
  }
}

/// Represents an operation that handles an error when received by an action in a reducer.
///
/// This is generally used to either set the error on the state or by throwing a runtime warning and
/// optionally logging the error.
///
public struct OnFailureOperation<State, Action>: Sendable {
  @usableFromInline
  let operation: @Sendable (inout State, Error) -> Effect<Action>

  /// Create a new operation.
  ///
  /// - Parameters:
  ///   - operation: The operation to run when a failure is received.
  @inlinable
  public init(
    _ operation: @escaping @Sendable (inout State, Error) -> Effect<Action>
  ) {
    self.operation = operation
  }

  /// Create a new operation that will set the error on the state at the given key path.
  ///
  /// - Parameters:
  ///   - operation: The set operation to used to handle the error.
  @inlinable
  public static func set(_ operation: SetOperation<State, Error>) -> Self {
    .init { state, error in
      operation(state: &state, value: error)
      return .none
    }
  }

  /// Create a new operation that will throw a runtime warning and log the error using the given logger.
  ///
  /// - Parameters:
  ///   - prefix: An optional string to prefix the error's description when logging.
  ///   - logger: The logger to use to log the error
  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  @inlinable
  public static func log(prefix: String? = nil, logger: Logger) -> Self {
    .log(prefix: prefix, log: { logger.error("\($0)") })
  }

  /// Create a new operation that will throw a runtime warning and optionally log the error using the given logger.
  ///
  /// - Parameters:
  ///   - prefix: An optional string to prefix the error's description when logging.
  ///   - log: An optional log handler to use to log the error.
  @inlinable
  public static func log(prefix: String? = nil, log: (@Sendable (String) -> Void)? = nil) -> Self {
    .init { _, error in
      guard let prefix else {
        return .fail(error: error, log: log)
      }
      return .fail(prefix: prefix, error: error, log: log)
    }
  }

  @usableFromInline
  func callAsFunction(state: inout State, error: Error) -> Effect<Action> {
    operation(&state, error)
  }
}

// A type that represents a path from an action to a case that accepts an error.
@usableFromInline
struct ToError<Action> {
  @usableFromInline
  let operation: (Action) -> Error?

  @usableFromInline
  init(_ casePath: AnyCasePath<Action, Error>) {
    operation = { casePath.extract(from: $0) }
  }

  @usableFromInline
  init<T>(_ result: AnyCasePath<Action, TaskResult<T>>) {
    operation = {
      let result = result.extract(from: $0)
      guard case let .failure(error) = result else { return nil }
      return error
    }
  }

  @usableFromInline
  func callAsFunction(action: Action) -> Error? {
    operation(action)
  }
}

/// A higher order reducer that is used to handle cases that accept an error.
///
/// This type is not created directly, instead use one of the `onfail` operations on your `Reducer`.
///
public struct _OnFailureReducer<Parent: Reducer>: Reducer {
  @usableFromInline
  let parent: Parent

  @usableFromInline
  let toError: ToError<Parent.Action>

  @usableFromInline
  let onFailAction: OnFailureOperation<Parent.State, Parent.Action>

  @usableFromInline
  init(
    parent: Parent,
    toError: ToError<Parent.Action>,
    onFailAction: OnFailureOperation<Parent.State, Parent.Action>
  ) {
    self.parent = parent
    self.toError = toError
    self.onFailAction = onFailAction
  }

  @inlinable
  public func reduce(
    into state: inout Parent.State,
    action: Parent.Action
  ) -> Effect<Parent.Action> {
    let baseEffects = parent.reduce(into: &state, action: action)

    guard let error = toError(action: action) else {
      return baseEffects
    }

    return .merge(
      baseEffects,
      onFailAction(state: &state, error: error)
    )
  }
}
