import ArgumentParser
import Foundation

struct ChangelogGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to generate changelogs for configured projects",
        subcommands: [CreateCommand.self, GenerateCommand.self, GenerateAllCommand.self])
    
    @OptionGroup var options: GlobalOptions
    
    public static var configFile: String = ("~/.config/changelog-generator.json" as NSString).expandingTildeInPath
    
    public static var config: Config = Config.newInstance()
    
    func validate() throws {
        let configFile = ChangelogGenerator.configFile
        guard let localData = try Config.readConfigFile(fromPath: configFile)
        else {
            return
        }
        print("Using \(configFile)")
        ChangelogGenerator.config = Config.parse(jsonData: localData)
    }
}

ChangelogGenerator.main()
