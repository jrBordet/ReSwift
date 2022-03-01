//
//  File.swift
//  
//
//  Created by Jean Raphael Bordet on 25/02/22.
//

import Foundation
import Combine
import XCTest

public class TestStore<State, Action>: ObservableObject {
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

extension TestStore {
	public func assertDispatch(
		step: StepType,
		action: Action,
		update: @escaping (inout State) -> Void,
		file: StaticString = #file,
		line: UInt = #line
	) where State: Equatable {
		
		switch step {
		case .send:
			reducer(&state, action)
			
		case .receive:
			let expectation = XCTestExpectation(description: "receivedCompletion")

			var expected = self.state
			
			reducer(&state, action)
			
			for mw in middlewares {
				guard let middleware = mw(state, action) else {
					break
				}
				
				middleware
					.receive(on: DispatchQueue.main)
					.sink { [weak self] subscribers in
						guard let self = self else {
							return
						}
						
						update(&expected)
						
						XCTAssertEqual(expected, self.state, file: file, line: line)
												
						expectation.fulfill()
					} receiveValue: { [weak self] receivedAction in
						print(action)
						//self?.assertDispatch(action: receivedAction, update: update)
					}
					.store(in: &middlewareCancellables)
				
				if XCTWaiter.wait(for: [expectation], timeout: 1) != .completed {
					XCTFail("Timed out waiting for the effect to complete")
				}
			}
			break
		}
		
	}
}

public enum StepType {
	case send
	case receive
}
