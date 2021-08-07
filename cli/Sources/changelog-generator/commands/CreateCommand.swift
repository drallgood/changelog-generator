import ArgumentParser
import Foundation

struct CreateCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "create", abstract: "Create a changelog JSON file")
    
    @Option(name: [.customShort("p"), .long], help: "Target directory")
    var path: String?
    
    @Option(name: [.customShort("r"), .long], help: "Reference")
    var reference: String
    
    @Option(name: [.customShort("t"), .long], help: "Title")
    var title: String
    
    @Option(name: [.customShort("l"), .long], help: "Type: \(ChangelogType.allCasesAsString())")
    var type: ChangelogType = .added
    
    func run() throws {
        
        let changelog = Changelog(title: title, reference: reference, type: type);
        
        var pathUrl: URL
        if (path == nil) {
            pathUrl = URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
        } else {
            pathUrl = URL(fileURLWithPath: path!)
        }
        let wrapper = ChangelogWrapper(changelogs: [changelog], file: pathUrl.appendingPathComponent("\(reference).json"))
        try ChangelogUtil.writeChangelogs(changelogWrapper: wrapper)
    }
}
