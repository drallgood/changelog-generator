import ArgumentParser

struct ProjectOptions: ParsableArguments {
    @OptionGroup var gitProjectOptions: GitProjectOptions
    
    @Option(name: [.customShort("p"), .long], help: "Path to projects file")
    var projectsConfig: String?
    
    func validate() throws {
        guard (!(projectsConfig == nil && gitProjectOptions.gitUrl == nil && gitProjectOptions.localPath == nil)) else {
            throw ValidationError("Please specify either a Git Url, a local path or a projects file")
        }
    }
}
