//
//  File.swift
//
//
//  Created by Patrice on 2/6/21.
//

import Foundation

struct Config: Encodable {
    var gitUrl: String?
    var gitAccessToken: String?
    var gitExecutablePath: String = "/usr/bin/git"
    var gitConnectorType: ConnectorType = ConnectorType.Gitlab
    var ticketBaseUrl: String?
    var validTicketStates: [String] = ["Added","Changed","Deprecated","Removed","Fixed","Security"]
}

extension Config: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gitUrl = try values.decodeIfPresent(String.self, forKey: .gitUrl)
        gitAccessToken = try values.decodeIfPresent(String.self, forKey: .gitAccessToken)
        ticketBaseUrl = try values.decodeIfPresent(String.self, forKey: .ticketBaseUrl)
        
        if let gitExecutablePathFromConfig = try values.decodeIfPresent(String.self, forKey: .gitExecutablePath) {
            gitExecutablePath = gitExecutablePathFromConfig
        }
        
        if let gitConnectorTypeFromConfig = try values.decodeIfPresent(ConnectorType.self, forKey: .gitConnectorType) {
            gitConnectorType = gitConnectorTypeFromConfig
        }
        
        if let validTicketStatesFromConfig = try values.decodeIfPresent([String].self, forKey: .validTicketStates) {
            validTicketStates = validTicketStatesFromConfig
        }
        
    }
}

extension Config {
    static func newInstance() -> Config {
        return Config(gitUrl: nil, gitAccessToken: nil, ticketBaseUrl: nil)
    }
    
    static func readConfigFile(fromPath path: String) throws -> Data? {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            return try String(contentsOfFile: path).data(using: .utf8)
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
        if let validTicketStatesString = ProcessInfo.processInfo.environment["CHANGELOG_TICKET_STATES"]{
            config.validTicketStates = validTicketStatesString.components(separatedBy: ",")
        }
        
        return config
    }
}
