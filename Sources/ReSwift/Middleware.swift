//
//  File.swift
//  
//
//  Created by Jean Raphael Bordet on 24/02/22.
//

import Foundation
import Combine

public typealias Middleware<State, Action> = (State, Action) -> AnyPublisher<Action, Never>
