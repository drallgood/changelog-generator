import ArgumentParser

struct GenerateOptions: ParsableArguments {
    @Argument(help: "The name of the release, e.g. 8.0.1")
    var release: String
    
    @Flag(name: [.long], help: "Push")
    var push: Bool = false
    
    @Flag(name: [.customShort("m"), .long], help: "Create merge request")
    var createMR: Bool = false
    
    @Flag(name: [.long], help: "Don't delete git project when finished")
    var noDelete: Bool = false
    
    @Option(name: [.customShort("t"), .long], help: "Personal access token (needed for merge request operations)")
    var accessToken: String?
    
    @Option(name: [.customShort("b"), .long], help: "Base branch")
    var baseBranch: String = "main"
    
    func validate() throws {
        guard !createMR || (createMR && accessToken != nil) else {
            throw ValidationError("Please specify a 'access-token'")
        }
    }
}
