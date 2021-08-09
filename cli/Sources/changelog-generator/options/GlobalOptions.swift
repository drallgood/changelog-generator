import ArgumentParser

/// Here you can specify parameters valid for all sub commands.
struct GlobalOptions: ParsableArguments {
    
    @Option(name: [.customShort("c"), .long])
    var configFile: String?
    
    @Flag(name: [.long], help: "Enable debug logging")
    var debug: Bool = false
    
    mutating func validate() throws {
        // Misusing validate to set the received flag globally
        if(configFile != nil) {
            ChangelogGenerator.configFile = configFile!
        }
        ChangelogGenerator.debugEnabled = debug
    }
}
