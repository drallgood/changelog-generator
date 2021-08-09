import ArgumentParser
import Foundation

struct CheckChangelogCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "check", abstract: "Check changelogs for a (set of) project(s)")
    
    @Option(name: [.customShort("g"), .long], help: "Git Url")
    var gitUrl: String?
    
    @Option(name: [.customShort("l"), .long], help: "Path to local git repo")
    var localPath: String?
    
    @Option(name: [.customShort("p"), .long], help: "Path to projects file")
    var projectsConfig: String?
    
    @Option(name: [.customShort("b"), .long], help: "Base branch")
    var baseBranch: String = "main"
    
    func validate() throws {
        guard (!(projectsConfig == nil && gitUrl == nil && localPath == nil)) else {
            throw ValidationError("Please specify either a Git Url, a local path or a projects file")
        }
    }
    
    func run() throws {
        if(projectsConfig != nil) {
            print("Using projects from \(projectsConfig!)")
            
            if let localData = try ProjectsConfig.readProjectsConfigFile(fromPath: projectsConfig!) {
                
                let projectsConfig = ProjectsConfig.parseProjectsConfig(jsonData: localData)
                projectsConfig.projects.forEach  { (project) in
                    checkChangelog(project: project)
                }
            }
        } else {
            let project = Project(title: "some project", gitUrl: self.gitUrl, localPath: self.localPath)
            checkChangelog(project: project)
        }
    }
    
    private func checkChangelog(project: Project) {
        let gitUtil = GitUtil()
        
        var projectPath: URL?
        let fileManager = FileManager.default
        
        signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            gitUtil.terminate()
            if(projectPath != nil && self.localPath == nil) {
                do {
                    try fileManager.removeItem(at: projectPath!)
                } catch {
                    print("Couldn't delete temporary directory at \(projectPath!)")
                }
            }
            GenerateCommand.exit(withError: ProcessError.exited(code: 0))
        }
        sigintSrc.resume()

        
        do {
            projectPath = try prepareGit(gitUtil: gitUtil, project: project)
            guard try checkChangelog(projectPath: projectPath!) else {
                return
            }
        
            if(self.localPath == nil) {
                try fileManager.removeItem(at: projectPath!)
            }
        } catch {
            print("Error when checking \(project.title): \(error.localizedDescription)")
        }
    }
    
    private func prepareGit(gitUtil: GitUtil, project: Project) throws -> URL {
        print("#### Checking out git project for \(project.title) ####")
        
        var projectPath: URL
        if(project.localPath == nil) {
            projectPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try gitUtil.checkoutGitProject(atUrl: project.gitUrl!, atPath: projectPath.path)
        } else  {
            projectPath = URL(fileURLWithPath: project.localPath!)
        }
        
        try gitUtil.assertOnCorrectBranchAndUpToDate(atPath: projectPath, branchName: self.baseBranch)
        return projectPath
    }
    
    private func checkChangelog(projectPath: URL) throws -> Bool  {
        let changelogsPath = projectPath.appendingPathComponent("changelogs")
        let changelogsList = ChangelogUtil.readChangelogs(fromPath: changelogsPath)
        if (changelogsList.count <= 0) {
            print("No changelogs found.")
            return false
        }
        return true
    }
}
