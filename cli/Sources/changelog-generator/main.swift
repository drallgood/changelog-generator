import ArgumentParser

struct ChangelogGenerator: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to generate changelogs for configured HIS projects",
        subcommands: [GenerateCommand.self])

    @OptionGroup var options: Options
    
    public static var configFile: String?
    
    init() { }
}

ChangelogGenerator.main()
