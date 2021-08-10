import ArgumentParser

struct GenerateOptions: ParsableArguments {
    
    @OptionGroup var gitServerOptions: GitServerOptions
    
    @Argument(help: "The name of the release, e.g. 8.0.1")
    var release: String
    
    @Flag(name: [.long], help: "Dry run")
    var dryRun: Bool = false
    
    @Option(name: [.customShort("b"), .long], help: "Base branch")
    var baseBranch: String = "main"
}
