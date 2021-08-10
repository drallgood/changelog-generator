//
//  File.swift
//  
//
//  Created by Patrice on 3/7/21.
//

import Foundation
protocol Connector {
    func createMR(forProject project: String, title: String, body: String, token: String, sourceBranchName: String, targetBranchName: String) throws
}

class ConnectorUtil {
    
    static func getConnector() -> Connector {
        switch ChangelogGenerator.config.gitConnectorType {
        case .Gitlab:
            return GitlabConnector(baseUrl: ChangelogGenerator.config.gitUrl!)
        case .Github:
            return GithubConnector(baseUrl: ChangelogGenerator.config.gitUrl!)
            
        }
    }
}
