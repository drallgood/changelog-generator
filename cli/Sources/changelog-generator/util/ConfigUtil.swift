import Foundation

class ConfigUtil {
    static func readConfigFile(fromPath path: String) -> Data? {
        do {
            return try String(contentsOfFile: path).data(using: .utf8)
        } catch {
            print(error)
        }
        
        return nil
    }
    
    static func parse(jsonData: Data) -> [Project] {
        do {
            let projectsWrapper = try JSONDecoder().decode(ProjectsWrapper.self,
                                                       from: jsonData)
            return projectsWrapper.projects
        } catch {
            print("decode error", error)
        }
        return []
    }
}
