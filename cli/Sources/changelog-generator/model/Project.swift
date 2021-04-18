import Foundation
struct Project: Codable {
    let title: String
    let gitUrl: String?
    let localPath: String?
}

struct ProjectsConfig: Codable {
    var projects: [Project] = []
}

extension ProjectsConfig {
    static func readProjectsConfigFile(fromPath path: String) throws -> Data? {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path) {
                return try String(contentsOfFile: path).data(using: .utf8)
            } else {
                throw ProcessError.NoConfigFound(path: path)
            }
    }
    
    static func parseProjectsConfig(jsonData: Data) -> ProjectsConfig {
        do {
            let projectsConfig = try JSONDecoder().decode(ProjectsConfig.self,
                                                          from: jsonData)
            return projectsConfig
        } catch {
            print("decode error", error)
        }
        return ProjectsConfig()
    }
}
