import ArgumentParser

/// Here you can specify parameters valid for all sub commands.
struct Options: ParsableArguments {

    @Option(name: [.customShort("c"), .long])
    var configFile: String

    mutating func validate() throws {
        // Misusing validate to set the received flag globally
        ChangelogGenerator.configFile = configFile
    }
}
