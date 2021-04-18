//
//  File.swift
//  
//
//  Created by Patrice on 3/7/21.
//

import Foundation
protocol Connector {
    func createMR(forProject project: String, release: String, token: String, sourceBranchName: String, targetBranchName: String) throws
}
