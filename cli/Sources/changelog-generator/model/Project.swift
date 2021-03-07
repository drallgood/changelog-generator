import Foundation
struct Project: Codable {
    let title: String
    let gitUrl: String?
    let localPath: String?
}

struct ProjectsWrapper: Codable {
    var projects: [Project] = []
}
