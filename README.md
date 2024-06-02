# TCAExtras

[![CI](https://github.com/m-housh/swift-tca-extras/actions/workflows/ci.yml/badge.svg)](https://github.com/m-housh/swift-tca-extras/actions/workflows/ci.yml)

A set of helpers and higher order reducers for use in `Composable Architecture`
projects.

## Installation

```swift
import PackageDescription

let package = Package(
  ...
  dependencies: [
    .package(
      url: "https://github.com/m-housh/swift-tca-extras.git",
      from: "0.1.0"
    )
  ],
  targets: [
    .target(
      name: "MyFeature",
      dependencies: [
        ...
        .product(name: "TCAExtras", package: "swift-tca-extras")
      ]
    )
    ...
  ]
)

```

## Basic Usage

This package includes several extensions to `Effect` and higher order reducers.
The general use case for actions that interact with dependencies that can throw
errors.

```swift
@Reducer
struct MyFeature {
  @ObservableState
  struct State: Equatable {
    var currentNumber: Int?
    var numberFact: String?
  }

  enum Action: ReceiveAction {
    case receive(TaskResult<ReceiveAction>)
    case task

    @CasePathable
    enum ReceiveAction {
      case currentNumber(Int)
      case numberFact(String)
    }
  }

  @Dependency(\.numberClient) var numberClient
  @Dependency(\.logger) var logger

  var body: some ReducerOf<Self> {
    // The ReceiveReducer handle's the success results, allowing you to
    // switch on the `Action.ReceiveAction` cases.
    ReceiveReducer { state, action in
      switch action {
      case let .currentNumber(currentNumber):
        state.currentNumber = currentNumber
        return .receive(\.numberFact) {
          // Run this operation, embedding the result in the `Action.receive`
          // result, on success it will further embed the value in the
          // `Action.ReceiveAction.numberFact` case.
          try await numberClient.fetchNumberFact(for: currentNumber)
        }
      case let .numberFact(numberFact):
        state.numberFact = numberFact
        return .none
    }
    // Handle the failure cases by logging the error and throwing a runtime
    // warning.
    .onFailure(.log(logger: logger))
    .receive(on: \.task, case: \.currentNumber) {
      // When the trigger action of `Action.task` is received,
      // then run this operation, embedding the result in the `Action.receive`
      // action, on success it will further embed the value in the
      // `Action.ReceiveAction.currentNumber` case.
      try await numberClient.fetchCurrentNumber()
    }
  }
}
```

The above example uses several of the reducers and effects that are supplied by
this package.
