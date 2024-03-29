//
//  ProcessError.swift
//  
//
//  Created by Patrice on 3/7/21.
//

import Foundation
enum ProcessError: Error {
    case exited(code:Int32)
    case NoConfigFound(path: String)
    case InvalidState(state: String)
    case URLError(url: String)
    
}

extension ProcessError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .exited(code: let code):
            return "Process exited with code \(code)"
        case .NoConfigFound(path: let path):
            return "No Configuration found at \(path)"
        case .InvalidState(state: let foundState):
            return "Found invalid state \"\(foundState)\". Allowed: \(ChangelogGenerator.config.validTicketStates)"
        case .URLError(let url):
            return "Error parsing URL: \(url)"
        }
    }
}
