import ArgumentParser

struct GitPushOptions: ParsableArguments {
    
    @Flag(name: [.long], help: "Push")
    var push: Bool = false
    
    @Flag(name: [.customShort("m"), .long], help: "Create merge request")
    var createMR: Bool = false
    
    @Option(name: [.customShort("t"), .long], help: "Personal access token (needed for merge request operations)")
    var accessToken: String?
    
    @Flag(name: [.long], help: "Dry run")
    var dryRun: Bool = false
    
    mutating func validate() throws {
        if(createMR) {
            push = true
        }
        
        if accessToken == nil {
            accessToken = ChangelogGenerator.config.gitAccessToken
        }
        
        guard !createMR || (createMR && accessToken != nil) else {
            throw ValidationError("Please specify an 'access token'")
        }
    }
}

struct GitProjectOptions: ParsableArguments {
    @Option(name: [.customShort("p"), .long], help: "Path to projects file")
    var projectsConfig: String?
    
    @Option(name: [.customShort("g"), .long], help: "Git Url")
    var gitUrl: String?
    
    @Option(name: [.customShort("l"), .long], help: "Path to local git repo")
    var localPath: String?
    
    @Option(name: [.customShort("b"), .long], help: "Base branch")
    var baseBranch: String = "main"
    
    @Flag(name: [.long], help: "Don't delete git project when finished")
    var noDelete: Bool = false
    
    @Flag(name: [.long], help: "Don't pull")
    var noPull: Bool = false
    
    func validate() throws {
        guard (!(projectsConfig == nil && gitUrl == nil && localPath == nil)) else {
            throw ValidationError("Please specify either a Git Url, a local path or a projects file")
        }
    }
}
