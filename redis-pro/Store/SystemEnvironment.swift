//
//  SystemEnvironment.swift
//  redis-pro
//
//  Created by chengpan on 2022/6/3.
//

import Foundation
import ComposableArchitecture

@dynamicMemberLookup
struct SystemEnvironment<Environment> {
  var date: () -> Date
  var environment: Environment
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var uuid: () -> UUID

  subscript<Dependency>(
    dynamicMember keyPath: WritableKeyPath<Environment, Dependency>
  ) -> Dependency {
    get { self.environment[keyPath: keyPath] }
    set { self.environment[keyPath: keyPath] = newValue }
  }

  /// Creates a live system environment with the wrapped environment provided.
  ///
  /// - Parameter environment: An environment to be wrapped in the system environment.
  /// - Returns: A new system environment.
  static func live(environment: Environment) -> Self {
    Self(
      date: Date.init,
      environment: environment,
      mainQueue: .main,
      uuid: UUID.init
    )
  }

  /// Transforms the underlying wrapped environment.
  func map<NewEnvironment>(
    _ transform: @escaping (Environment) -> NewEnvironment
  ) -> SystemEnvironment<NewEnvironment> {
    .init(
      date: self.date,
      environment: transform(self.environment),
      mainQueue: self.mainQueue,
      uuid: self.uuid
    )
  }
}
