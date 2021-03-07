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
    static func readProjectsConfigFile(fromPath path: String) -> Data? {
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: path) {
                return try String(contentsOfFile: path).data(using: .utf8)
            } else {
                print("File Not found at \(path)")
            }
        } catch {
            print(error)
        }
        
        return nil
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
