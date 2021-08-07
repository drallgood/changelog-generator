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
        switch argument {
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
        default:
            return nil
        }
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
