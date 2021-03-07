//
//  ProcessError.swift
//  
//
//  Created by Patrice on 3/7/21.
//

import Foundation
enum ProcessError: Error {
    case exited(code:Int32)
}

extension ProcessError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .exited(code: let code):
            return "Process exited with code \(code)"
        }
    }
}
