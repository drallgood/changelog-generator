import Foundation

enum ChangelogType: String, Codable, CaseIterable {
           case security
           case removed
           case fixed
           case deprecated
           case changed
           case performance
           case added
           case other
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
