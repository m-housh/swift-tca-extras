import ComposableArchitecture
import OSLog

extension Effect {
  /// An effect that throws a runtime warning and optionally logs an error message.
  ///
  /// This effect uses `XCTFail`  to throw a runtime warning and will also log the message
  /// if a logger is supplied.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///  ...
  ///  enum Action {
  ///    case receive(TaskResult<Int>)
  ///    ...
  ///  }
  ///
  ///  @Dependency(\.logger) var logger
  ///
  ///  var body: some ReducerOf<Self> {
  ///    Reduce { state, action in
  ///      switch action {
  ///        case .receive(.failure(_)):
  ///          return .fail("Failed retreiving number fact.", log: { logger.debug("\($0)") })
  ///        ...
  ///
  ///      }
  ///    }
  ///  }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - message: The message for the failure reason.
  ///   - logger: An optional logger to use to log the message.
  public static func fail(
    _ message: String,
    log: (@Sendable (String) -> Void)? = nil
  ) -> Self {
    fail(.init(message, log: log))
  }

  /// An effect that throws a runtime warning and optionally logs an error message.
  ///
  /// This effect uses `XCTFail`  to throw a runtime warning and will also log the message
  /// if a logger is supplied.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///  ...
  ///  enum Action {
  ///    case receive(TaskResult<Int>)
  ///    ...
  ///  }
  ///
  ///  @Dependency(\.logger) var logger
  ///
  ///  var body: some ReducerOf<Self> {
  ///    Reduce { state, action in
  ///      switch action {
  ///        case .receive(.failure(_)):
  ///          return .fail("Failed retreiving number fact.", logger: logger)
  ///        ...
  ///
  ///      }
  ///    }
  ///  }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - message: The message for the failure reason.
  ///   - logger: An optional logger to use to log the message.
  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  public static func fail(
    _ message: String,
    logger: Logger? = nil
  ) -> Self {
    fail(message, log: { logger?.error("\($0)") })
  }

  /// An effect that throws a runtime warning and optionally logs an error message.
  ///
  ///
  /// This effect uses `XCTFail`  to throw a runtime warning and will also log the message
  /// if a logger is supplied.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///  ...
  ///  enum Action {
  ///    case receive(TaskResult<Int>)
  ///    ...
  ///  }
  ///
  ///  @Dependency(\.logger) var logger
  ///
  ///  var body: some ReducerOf<Self> {
  ///    Reduce { state, action in
  ///      switch action {
  ///        case let .receive(.failure(error)):
  ///          return .fail(error: error, logger: logger)
  ///        ...
  ///
  ///      }
  ///    }
  ///  }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - prefix: The prefix for the error message for the failure.
  ///   - error: The error for the failure..
  ///   - logger: A logger to use to log the message.
  @available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
  public static func fail(
    prefix: String = "Failed error:",
    error: any Error,
    logger: Logger
  ) -> Self {
    fail(prefix: prefix, error: error, log: { logger.error("\($0)") })
  }

  /// An effect that throws a runtime warning and optionally logs an error message.
  ///
  ///
  /// This effect uses `XCTFail`  to throw a runtime warning and will also log the message
  /// if a logger is supplied.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @Reducer
  /// struct MyFeature {
  ///  ...
  ///  enum Action {
  ///    case receive(TaskResult<Int>)
  ///    ...
  ///  }
  ///
  ///  @Dependency(\.logger) var logger
  ///
  ///  var body: some ReducerOf<Self> {
  ///    Reduce { state, action in
  ///      switch action {
  ///        case .receive(.failure(_)):
  ///          return .fail("Failed retreiving number fact.", log: { logger.debug("\($0)") })
  ///        ...
  ///
  ///      }
  ///    }
  ///  }
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - prefix: The prefix for the error message for the failure.
  ///   - error: The error for the failure..
  ///   - log: A log handler to use to log the message.
  public static func fail(
    prefix: String = "Failed error:",
    error: any Error,
    log: (@Sendable (String) -> Void)? = nil
  ) -> Self {
    fail(.init(prefix: prefix, error: error, log: log))
  }

  @usableFromInline
  static func fail(_ effect: FailEffect<Action>) -> Self {
    effect()
  }
}

@usableFromInline
struct FailEffect<Action>: Sendable {
  let message: String
  let log: (@Sendable (String) -> Void)?

  @usableFromInline
  init(_ message: String, log: (@Sendable (String) -> Void)? = nil) {
    self.message = message
    self.log = log
  }

  @usableFromInline
  init(
    prefix: String = "Failed error:",
    error: Error,
    log: (@Sendable (String) -> Void)? = nil
  ) {
    self.init(
      "\(prefix) \(error.localizedDescription)",
      log: log
    )
  }

  @usableFromInline
  func callAsFunction() -> Effect<Action> {
    XCTFail("\(message)")
    log?(message)
    return .none
  }
}
