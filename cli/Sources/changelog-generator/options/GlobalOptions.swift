import ArgumentParser

/// Here you can specify parameters valid for all sub commands.
struct GlobalOptions: ParsableArguments {
    
    @Option(name: [.customShort("c"), .long])
    var configFile: String?
    
    mutating func validate() throws {
        // Misusing validate to set the received flag globally
        if(configFile != nil) {
            ChangelogGenerator.configFile = configFile!
        }
    }
}
