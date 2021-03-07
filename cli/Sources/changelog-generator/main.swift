import ArgumentParser
import Foundation

struct ChangelogGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to generate changelogs for configured HIS projects",
        subcommands: [GenerateCommand.self, GenerateAllCommand.self])

    @OptionGroup var options: GlobalOptions
    
    public static var configFile: String = ("~/.config/changelog-generator.json" as NSString).expandingTildeInPath
    
    public static var config: Config = Config.newInstance()
    
    init() {
        let configFile = ChangelogGenerator.configFile
        guard let localData = Config.readConfigFile(fromPath: configFile)
        else {
            return
        }
        print("Using \(configFile)")
        ChangelogGenerator.config = Config.parse(jsonData: localData)
    }
}

ChangelogGenerator.main()
