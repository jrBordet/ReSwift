//
//  File.swift
//  
//
//  Created by Jean Raphael Bordet on 24/02/22.
//

import Foundation

public typealias Reducer<State, Action> = (inout State, Action) -> Void//State
