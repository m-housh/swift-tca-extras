import ComposableArchitecture

extension Effect {
  @usableFromInline
  static func receive<Input, Result>(
    operation: ReceiveOperation<Action, Input, Result>
  ) -> Self {
    .run { send in
      await operation(send: send)
    }
  }

  /// A convenience effect for sending an action that receives a task result from the given operation.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receive(TaskResult<Int>)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberClient) var numberClient
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce { state, action in
  ///       switch action {
  ///         ...
  ///         case .task:
  ///           return .receive(action: \.receive) {
  ///             try await numberClient.numberFact()
  ///           }
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - action: The action to embed the task result in.
  ///   - operation: The operation to call to create the task result.
  @inlinable
  public static func receive<T>(
    action toResult: CaseKeyPath<Action, TaskResult<T>>,
    operation: @escaping @Sendable () async throws -> T
  ) -> Self {
    .receive(operation: .case(AnyCasePath(toResult), operation))
  }

  /// A convenience effect for sending an action that receives a task result from the given operation and then
  /// transforming the output of the operation.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   ...
  ///   enum Action {
  ///     case receive(TaskResult<String>)
  ///     case task
  ///   }
  ///
  ///   @Dependency(\.numberClient) var numberClient
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce { state, action in
  ///       switch action {
  ///         ...
  ///         case .task:
  ///           return .receive(action: \.receive) {
  ///             try await numberClient.numberFact()
  ///           } transform: { number in
  ///             "The current number fact is: \(number)"
  ///           }
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - action: The action to embed the task result in.
  ///   - operation: The operation to call to create the task result.
  ///   - transform: The operation used to transform the output of the operation.
  @inlinable
  public static func receive<T, V>(
    action toResult: CaseKeyPath<Action, TaskResult<V>>,
    operation: @escaping @Sendable () async throws -> T,
    transform: @escaping @Sendable (T) -> V
  ) -> Self {
    .receive(operation: .case(AnyCasePath(toResult), operation, transform))
  }
}

extension Effect where Action: ReceiveAction {
  /// A convenience effect for sending an action that receives a task result from the given operation and then
  /// transforming the output of the operation.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///   ...
  ///   enum Action: ReceiveAction {
  ///     case receive(TaskResult<ReceiveAction>)
  ///     case task
  ///
  ///     @CasePathable
  ///     enum ReceiveAction {
  ///       case numberFact(String)
  ///     }
  ///   }
  ///
  ///   @Dependency(\.numberClient) var numberClient
  ///
  ///   var body: some Reducer<State, Action> {
  ///     Reduce { state, action in
  ///       switch action {
  ///         ...
  ///         case .task:
  ///           return .receive(\.numberFact) {
  ///             try await numberClient.numberFact()
  ///           }
  ///       }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - action: The action to embed the task result in.
  ///   - operation: The operation to call to create the task result.
  @inlinable
  public static func receive<T>(
    _ toReceiveAction: CaseKeyPath<Action.ReceiveAction, T>,
    _ operation: @escaping @Sendable () async throws -> T
  ) -> Self {
    receive(
      operation: .case(
        AnyCasePath(toReceiveAction),
        operation
      ))
  }
}

// A container that holds onto the required data for embedding a task result into
// an action and optionally transforming the output.
@usableFromInline
struct ReceiveOperation<Action, Value, Result> {
  @usableFromInline
  let embed: @Sendable (TaskResult<Result>) -> Action

  @usableFromInline
  let operation: @Sendable () async throws -> Value

  @usableFromInline
  let transform: @Sendable (Value) -> Result

  @usableFromInline
  func callAsFunction(send: Send<Action>) async {
    await send(
      embed(
        TaskResult { try await operation() }
          .map(transform)
      ))
  }

  @usableFromInline
  static func `case`(
    _ casePath: AnyCasePath<Action, TaskResult<Result>>,
    _ operation: @escaping @Sendable () async throws -> Value,
    _ transform: @escaping @Sendable (Value) -> Result
  ) -> Self {
    .init(embed: { casePath.embed($0) }, operation: operation, transform: transform)
  }

  @usableFromInline
  static func `case`(
    _ casePath: AnyCasePath<Action, TaskResult<Result>>,
    operation: @escaping @Sendable () async throws -> Value,
    embedIn embedInCase: AnyCasePath<Result, Value>
  ) -> Self {
    .case(casePath, operation) {
      embedInCase.embed($0)
    }
  }
}

extension ReceiveOperation where Value == Result {
  @usableFromInline
  init(
    embed: @escaping @Sendable (TaskResult<Result>) -> Action,
    operation: @escaping @Sendable () async throws -> Value
  ) {
    self.init(embed: embed, operation: operation, transform: { $0 })
  }

  @usableFromInline
  static func `case`(
    _ casePath: AnyCasePath<Action, TaskResult<Result>>,
    _ operation: @escaping @Sendable () async throws -> Value
  ) -> Self {
    .init(embed: { casePath.embed($0) }, operation: operation)
  }
}

extension ReceiveOperation where Action: ReceiveAction, Result == Action.ReceiveAction {
  @usableFromInline
  static func `case`(
    _ embedInCase: AnyCasePath<Action.ReceiveAction, Value>,
    _ operation: @escaping @Sendable () async throws -> Value
  ) -> Self {
    .case(
      AnyCasePath(unsafe: Action.receive),
      operation: operation,
      embedIn: embedInCase
    )
  }
}
