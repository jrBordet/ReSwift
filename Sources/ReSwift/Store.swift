//
//  File.swift
//  
//
//  Created by Jean Raphael Bordet on 24/02/22.
//

import Foundation
import Combine

public class Store<State, Action>: ObservableObject {
//	@Published private(set) var state: State
	
	@Published public var state: State

	
	private let reducer: Reducer<State, Action>
	
	private let queue = DispatchQueue(
		label: "com.jrbordet.redux.store",
		qos: .userInitiated
	)
	
	private let middlewares: [Middleware<State, Action>]
	
	private var subscriptions: Set<AnyCancellable> = []
	
	public init(
		initial: State,
		reducer: @escaping Reducer<State, Action>,
		middlewares: [Middleware<State, Action>] = []
	) {
		self.state = initial
		self.reducer = reducer
		self.middlewares = middlewares
	}
	
	private func dispatch(_ currentState: State, _ action: Action) {
		let newState = reducer(currentState, action)
		
		middlewares.forEach { middleware in
			let publisher = middleware(newState, action)
			publisher
				.receive(on: DispatchQueue.main)
				.sink(receiveValue: dispatch)
				.store(in: &subscriptions)
		}
		
		state = newState
	}
	
	// MARK: - Interface
	
	public func dispatch(_ action: Action) {
		queue.sync { [weak self] in
			guard let self = self else {
				return
			}
			
			self.dispatch(self.state, action)
		}
	}
	
}
