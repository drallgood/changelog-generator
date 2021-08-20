import ArgumentParser
import Foundation

struct GenerateCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "generate", abstract: "Generate Changelogs for a project")
    
    @OptionGroup var options: GenerateOptions
    
    @OptionGroup var gitProjectOptions: GitProjectOptions
    
    var title: String?
    
    init() {
    }
    
    // Used when calling from another command
    init(options: GenerateOptions, title: String?, gitUrl: String?, localPath:String?) {
        self.options = options
        self.gitProjectOptions = setupGitProjectOptions(gitUrl: gitUrl, localPath: localPath)
        self.gitProjectOptions.baseBranch = options.baseBranch
        self.title = title
    }
    
    private func setupGitProjectOptions(gitUrl: String?, localPath:String?) -> GitProjectOptions  {
        var projectOptions:[String] = []
        if(gitUrl != nil) {
            projectOptions.append(contentsOf: ["-g",gitUrl!])
        }
        if(localPath != nil) {
            projectOptions.append(contentsOf: ["-l",localPath!])
        }
        return GitProjectOptions.parseOrExit(projectOptions)
    }
    
    
    mutating func validate() throws {
        guard (gitProjectOptions.gitUrl != nil || gitProjectOptions.localPath != nil) else {
            throw ValidationError("Please specify either a Git Url or a local path")
        }
    }
    
    func run() throws {
        let branchName = "CL-\(options.release)"
        let fileManager = FileManager.default
        let gitUtil = GitUtil()
        
        var projectPath: URL?
        
        var connector:Connector?
        if(options.gitServerOptions.createMR) {
            connector = ConnectorUtil.getConnector()
        }
        
        signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            gitUtil.terminate()
            if(!gitProjectOptions.noDelete && projectPath != nil) {
                do {
                    try fileManager.removeItem(at: projectPath!)
                } catch {
                    print("Couldn't delete temporary directory at \(projectPath!)")
                }
            }
            GenerateCommand.exit(withError: ProcessError.exited(code: 0))
        }
        sigintSrc.resume()
        
        let project = Project(title: self.title ?? "", gitUrl: gitProjectOptions.gitUrl, localPath: gitProjectOptions.localPath)
        do {
            projectPath = try gitUtil.prepareGit(project: project, baseBranch:gitProjectOptions.baseBranch, branchName: branchName)
            guard try generateChangelog(projectPath: projectPath!) else {
                return
            }
            
            try gitUtil.commitChanges(gitUtil: gitUtil, projectPath: projectPath!, branchName: branchName, message: "Updating changelog for \(options.release)", push: options.gitServerOptions.push, dryRun: options.dryRun)
            
            if(options.gitServerOptions.createMR && !options.dryRun) {
                guard let projectName = gitUtil.extractProjectName(project.gitUrl!) else {
                    print("ERROR: couldn't extract project name from \(project.gitUrl!)")
                    return
                }
                try connector?.createMR(forProject: projectName, title: "Merge changelog for \(options.release) to \(gitProjectOptions.baseBranch)", body: "Generated changelog for \(options.release). Branch \(branchName) to \(gitProjectOptions.baseBranch)",token: options.gitServerOptions.accessToken!, sourceBranchName: branchName, targetBranchName: gitProjectOptions.baseBranch)
            }
            
            if(!gitProjectOptions.noDelete) {
                try fileManager.removeItem(at: projectPath!)
            }
        } catch {
            print("Error when generating \(project.title): \(error.localizedDescription)")
        }
    }
    
    
    
    private func generateChangelog(projectPath: URL) throws -> Bool  {
        let changelogsPath = projectPath.appendingPathComponent("changelogs")
        let changelogsList = ChangelogUtil.readChangelogs(fromPath: changelogsPath)
        if (changelogsList.count <= 0) {
            print("No changelogs found.")
            return false
        }
        
        let sortedLogs = ChangelogUtil.sortByType(changelogsList: changelogsList)
        print("Generating markdown")
        let markdownString = ChangelogUtil.generateMarkdown(changelogs: sortedLogs, release: options.release)
        if(ChangelogGenerator.debugEnabled) {
            print(markdownString)
        }
        print("Updating CHANGELOG.md")
        ChangelogUtil.appendToChangelogFile(filePath: projectPath.appendingPathComponent("CHANGELOG.md"), content: markdownString)
        print("Archiving changelogs for \(options.release)")
        try ChangelogUtil.archiveChangelogs(fromPath: changelogsPath, release: options.release)
        return true
    }
}
