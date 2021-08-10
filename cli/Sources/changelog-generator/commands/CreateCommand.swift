import ArgumentParser
import Foundation

struct CreateCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "create", abstract: "Create a changelog JSON file")
    
    @Option(name: [.customShort("p"), .long], help: "Target directory", completion: .directory)
    var path: String?
    
    @Option(name: [.customShort("f"), .long], help: "Filename to create")
    var fileName: String?
    
    @Option(name: [.customShort("r"), .long], help: "Reference of the entry, e.g. ticket number")
    var reference: String?
    
    @Option(name: [.customShort("t"), .long], help: "Text describing the change")
    var title: String
    
    @Option(name: [.customShort("w"), .long], help: "Type of change. One of: \(ChangelogType.allCasesAsString())")
    var type: ChangelogType = .added
    
    func validate() throws {
        guard (fileName != nil || reference != nil) else {
            throw ValidationError("Please provide either a file name or a reference")
        }
    }
    
    func run() throws {
        
        let changelog = Changelog(title: title, reference: reference ?? "", type: type);
        
        var pathUrl: URL
        if (path == nil) {
            pathUrl = URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("changelogs")
        } else {
            pathUrl = URL(fileURLWithPath: path!)
        }
        
        let file = fileName ?? reference!
        
        let wrapper = ChangelogWrapper(changelogs: [changelog], file: pathUrl.appendingPathComponent("\(file).json"))
        try ChangelogUtil.writeChangelogs(changelogWrapper: wrapper)
    }
}
