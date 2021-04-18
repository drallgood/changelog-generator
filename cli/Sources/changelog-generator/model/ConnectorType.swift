//
//  File.swift
//  
//
//  Created by Patrice on 3/7/21.
//

enum ConnectorType: String, Codable, CaseIterable {
    case Gitlab
    case Github
}

extension ConnectorType {
    
    init?(argument: String) {
        switch argument {
        case "Gitlab":
            self = .Gitlab
            break
        case "Github":
            self = .Github
            break
        default:
            return nil
        }
    }
    
    static func allCasesAsString() -> String {
        return ConnectorType.allCases.map({ "\($0)" })
            .joined(separator: ", ")
    }
}
