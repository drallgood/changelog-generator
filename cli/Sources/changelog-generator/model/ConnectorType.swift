//
//  File.swift
//  
//
//  Created by Patrice on 3/7/21.
//

enum ConnectorType: String, Codable, CaseIterable {
    case Gitlab
}

extension ConnectorType {
    
    init?(argument: String) {
        switch argument {
        case "Gitlab":
            self = .Gitlab
        default:
            return nil
        }
    }
    
    static func allCasesAsString() -> String {
        return ConnectorType.allCases.map({ "\($0)" })
            .joined(separator: ", ")
    }
}
