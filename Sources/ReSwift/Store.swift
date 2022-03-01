//
//  File.swift
//  
//
//  Created by Jean Raphael Bordet on 24/02/22.
//

import Foundation
import Combine

public class Store<State, Action>: ObservableObject {
	@Published public private(set) var state: State
		
	private let reducer: Reducer<State, Action>
	
	var tasks = [AnyCancellable]()
	
	private let middlewares: [Middleware<State, Action>]
	private var middlewareCancellables: Set<AnyCancellable> = []
		
	public init(
		initial: State,
		reducer: @escaping Reducer<State, Action>,
		middlewares: [Middleware<State, Action>] = []
	) {
		self.state = initial
		self.reducer = reducer
		self.middlewares = middlewares
	}
	
	// MARK: - Interface
	
	public func dispatch(_ action: Action) {
		reducer(&state, action)
 
		// Dispatch all middleware functions
		for mw in middlewares {
			guard let middleware = mw(state, action) else {
				break
			}
			
			middleware
				.receive(on: DispatchQueue.main)
				.sink(receiveValue: dispatch)
				.store(in: &middlewareCancellables)
		}
	}
}
