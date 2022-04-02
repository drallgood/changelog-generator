import Foundation
import ArgumentParser

enum ChangelogType: String, Codable, CaseIterable, ExpressibleByArgument {
    case security
    case removed
    case fixed
    case deprecated
    case changed
    case performance
    case added
    case other
}

extension ChangelogType {
    
    init?(argument: String) {
        switch argument.lowercased() {
        case "security":
            self = .security
        case "removed":
            self = .removed
        case "fixed":
            self = .fixed
        case "deprecated":
            self = .deprecated
        case "changed":
            self = .changed
        case "performance":
            self = .performance
        case "added":
            self = .added
        case "other":
            self = .other
        // Some common mistakes
        case "remove":
            self = .removed
        case "removes":
            self = .removed
        case "fix":
            self = .fixed
        case "fixing":
            self = .fixed
        case "fixes":
            self = .fixed
        case "add":
            self = .added
        case "adds":
            self = .added
        case "adding":
            self = .added
        case "change":
            self = .changed
        case "changes":
            self = .changed
        default:
            return nil
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let type = try? container.decode(String.self)
        self.init(argument: type!)!
    }
    
    static func allCasesAsString() -> String {
        return ChangelogType.allCases.map({ "\($0)" })
            .joined(separator: ", ")
    }
}


struct Changelog: Codable {
    let title: String
    let reference: String
    let type: ChangelogType
}

struct ChangelogWrapper {
    let changelogs: [Changelog]
    let file: URL
}
