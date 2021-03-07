//
//  File.swift
//
//
//  Created by Patrice on 2/6/21.
//

import Foundation

struct Config: Codable {
    var gitUrl: String?
    var gitAccessToken: String?
    var gitExecutablePath: String = "/usr/bin/git"
    var gitConnectorType: ConnectorType = ConnectorType.Gitlab
    var ticketBaseUrl: String?
    
}

extension Config {
    static func newInstance() -> Config {
        return Config(gitUrl: "", gitAccessToken: "", ticketBaseUrl: "")
    }
    
    static func readConfigFile(fromPath path: String) -> Data? {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path) {
                return try String(contentsOfFile: path).data(using: .utf8)
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    static func parse(jsonData: Data) -> Config  {
        var config: Config
        do {
            config = try JSONDecoder().decode(Config.self, from: jsonData)
        } catch {
            print("decode error", error)
            config = Config.newInstance()
        }
        
        if let gitExecutablePath = ProcessInfo.processInfo.environment["GIT_EXECUTABLE_PATH"]{
            config.gitExecutablePath = gitExecutablePath
        }
        
        if let gitUrl = ProcessInfo.processInfo.environment["CHANGELOG_GIT_URL"]{
            config.gitUrl = gitUrl
        }
        
        if let gitAccessToken = ProcessInfo.processInfo.environment["CHANGELOG_GIT_ACCESS_TOKEN"]{
            config.gitAccessToken = gitAccessToken
        }
        
        if let ticketBaseUrl = ProcessInfo.processInfo.environment["CHANGELOG_TICKET_BASE_URL"]{
            config.ticketBaseUrl = ticketBaseUrl
        }
        
        return config
    }
}
